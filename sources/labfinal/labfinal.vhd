/*
Proyecto final de DAS

Realizado por Enrique R�os

Flappy Bird Doble Concurrente

Usando el estándar VHDL'08
*/

/*
Automatic System Designing final project

Done by Enrique Rios

Double Flappy Bird

Using standard VHDL'08
*/

library ieee;
use ieee.std_logic_1164.all;

entity labfinal is
  port ( 
    clk      : in  std_logic;
    rst      : in  std_logic;
    mode     : in  std_logic;
    background : in std_logic;
    -- 8 segments side
    segs_n   : out std_logic_vector(7 downto 0);
    an_n     : out std_logic_vector(3 downto 0);
    -- Keyboard side
    ps2Clk   : in  std_logic;
    ps2Data  : in  std_logic;
    -- VGA side
    hSync    : out  std_logic;
    vSync    : out  std_logic;
    RGB      : out  std_logic_vector(11 downto 0);
    -- Speaker side
    speaker  : out std_logic;
    -- Camera side   
    pClk   : in  std_logic;
    xClk   : out std_logic;
    cvSync : in  std_logic;
    hRef   : in  std_logic;
    cData  : in  std_logic_vector(7 downto 0);
    sioc   : out std_logic;
    siod   : out std_logic;
    pwdn   : out std_logic;
    rst_n  : out std_logic
  );
end labfinal;

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of labfinal is
  component frameBuffer
    port (
      clka : IN STD_LOGIC;
      wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
      dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
      clkb : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
  end component;
    
  component multAdd
    port (
      A : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      B : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      C : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      SUBTRACT : IN STD_LOGIC;
      P : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      PCOUT : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
    );
  end component;

  constant FREQ_KHZ : natural := 100_000;        -- Basys3 base frequency
  constant FREQ_HZ  : natural := FREQ_KHZ*1000;  -- Basys3 base frequency (Hz)
  constant VGA_KHZ  : natural := 25_000;
  constant FREQ_DIV : natural := FREQ_KHZ/VGA_KHZ;

  constant PIXELSxLINE : natural := 640;
  constant LINESxFRAME : natural := 480;

  constant POINTSxLINE : natural := PIXELSxLINE / 4;
  constant POINTLINESxFRAME : natural := LINESxFRAME / 4;

  -- Sizes and positions for birds in points
  constant BIRD_SIZE : natural := 4;
  constant DEFAULT_Y_BIRDS : natural := POINTLINESxFRAME - 16 - 1; 
  
  -- Sizes of moving walls
  constant HEIGHT_MOVING_WALLS : natural := 2;
  constant GAP_MOVING_WALLS : natural := 16;
  
  
  -- Signals
  signal rstSync,backgroundSync : std_logic;
  signal data: std_logic_vector(7 downto 0);
  signal dataRdy: std_logic;

  signal color          : std_logic_vector(11 downto 0);
  signal move50, move60, endLeftGame, endRightGame, showLeftWall, showRightWall, restart : boolean;
  
  signal lineAux, pixelAux : std_logic_vector(9 downto 0);  
  signal line, pixel    : unsigned(7 downto 0);

  signal seedLeft, seedRight, randomLeft, randomRight   : std_logic_vector(5 downto 0);
  
  signal soundEnable : std_logic;
  
  signal progRdy, rec, xclkRdy : std_logic;
  
  signal wea            : std_logic_vector(0 downto 0);
  signal wrAddr, rdAddr : std_logic_vector(16 downto 0);
  signal wrData, rdData : std_logic_vector(11 downto 0);
  
  signal wrY, rdY : std_logic_vector(8 downto 0);
  signal rdYaux   : std_logic_vector(9 downto 0);
  signal wrX, rdX : std_logic_vector(9 downto 0);
  signal wrYaux   : std_logic_vector(9 downto 0);

  -- Registers
  signal xLeftWall      : unsigned(7 downto 0) := to_unsigned(30, 8);
  signal yLeftWall      : unsigned(7 downto 0) := to_unsigned(5, 8);
  
  signal xRightWall     : unsigned(7 downto 0) := to_unsigned(118, 8);
  signal yRightWall     : unsigned(7 downto 0) := to_unsigned(5, 8);
  
  signal xLeftBird      : unsigned(7 downto 0) := to_unsigned(39, 8);
  signal xRightBird     : unsigned(7 downto 0) := to_unsigned(118, 8);

  signal counterLeft    :  unsigned(7 downto 0) := to_unsigned(0, 8);
  signal counterRight   : unsigned(7 downto 0) := to_unsigned(0, 8); 
  
  signal speakerTFF     : std_logic := '0';
  
  signal zP, cP, bP, mP, spcP: boolean := false;
  
  begin 

    resetSynchronizer : synchronizer
      generic map(STAGES  => 2, XPOL => '0')
      port map(clk => clk, x => rst, xSync => rstSync);
      
    cctvOnSynchronizer : synchronizer
      generic map ( STAGES => 2, XPOL => '0')
      port map ( clk => clk, x => background, xSync => backgroundSync );
    
    ------------------

    ps2KeyboardInterface : ps2receiver
      port map ( clk => clk, rst => rstSync, dataRdy => dataRdy, data => data, ps2Clk => ps2Clk, ps2Data => ps2Data );

    keyboardScanner:
      process (clk)
        type states is (keyON, keyOFF);
        variable state : states := KeyON;
      begin
        if rising_edge(clk) then
          if rstSync='1' then
            state := KeyON;
            spcP <= false;
            zP <= false;
            cP <= false;
            bP <= false;
            mP <= false;
          elsif dataRdy='1' then
            case state is
              when keyON =>
                state := keyON;
                case data is
                  when X"F0" => state := keyOFF;
                  when X"29" => spcP <= true;
                  when X"1A" => zP <= true;
                  when X"21" => cP <= true;
                  when X"32" => bP <= true;
                  when X"3A" => mP <= true;
                  when others => null;
                end case;
              when keyOFF =>
                state := keyON;
                case data is
                  when X"29" => spcP <= false;
                  when X"1A" => zP <= false;
                  when X"21" => cP <= false;
                  when X"32" => bP <= false;
                  when X"3A" => mP <= false;
                  when others => null;
                end case;
            end case;
          end if;
        end if;
      end process;
    
    ------------------
    
    speakerCycleCounter :
    process (clk)
      variable count : natural := 0;
    begin
      if rising_edge(clk) then
        if (count = 0) then
            count := FREQ_HZ/(2*440);
            speakerTFF <= not speakerTFF;
        else
            count := count - 1;
        end if;
      end if; 
    end process;
    
    speaker <= 
      speakerTFF when soundEnable = '1' else '0';
    
    ------------------
    
    displayInterface : segsBankRefresher
    generic map(FREQ_KHZ => FREQ_KHZ, SIZE => 4)
    port map(clk => clk, 
            ens => "1111", 
            bins => std_logic_vector(counterLeft(7 downto 4)) & std_logic_vector(counterLeft(3 downto 0)) & std_logic_vector(counterRight(7 downto 4)) & std_logic_vector(counterRight(3 downto 0)), 
            dps => "0000", 
            an_n => an_n, 
            segs_n => segs_n
        );
    
    ------------------

    restartSignal:
    process(all)
    begin
      -- con que uno de los dos falle pierde
      if (mode = '0') then
        restart <= spcP and (endLeftGame or endRightGame);
      -- si uno falla, el otro puede seguir jugando
      else
        restart <= spcP and endLeftGame and endRightGame;
      end if;
    end process;

    ------------------

    pulseGen:
    process (clk)
      constant CYCLES50 : natural := hz2cycles(FREQ_KHZ, 50);
      constant CYCLES60 : natural := hz2cycles(FREQ_KHZ, 60);
      variable count50  : natural range 0 to CYCLES50-1 := 0;
      variable count60  : natural range 0 to CYCLES60-1 := 0;
    begin
      if rising_edge(clk) then
          if rstSync = '1' then
              count50 := 0;
              count60 := 0;
              move50 <= false;
              move60 <= false;
          else
            move50 <= false;
            move60 <= false;
            if endLeftGame and endRightGame and mode = '1' then
              count50 := 0;
              count60 := 0;
            elsif (endLeftGame or endRightGame) and mode = '0' then
              count50 := 0;
              count60 := 0;
            else
              count50 := count50 + 1 mod CYCLES50;
              count60 := count60 + 1 mod CYCLES60;
              if count50 = CYCLES50 - 1 then
                move50 <= true;
              end if;
              if count60 = CYCLES60 - 1 then
                move60 <= true;
              end if;
            end if;
          end if;
      end if;
    end process;
    
    ------------------
    
    seedRegister: 
      process(clk)
        variable cntLeft : unsigned(5 downto 0) := (others => '0');
        variable cntRight : unsigned(5 downto 0) := "110111";
      begin
        if rising_edge(clk) then
          cntLeft := (cntLeft + 1) mod "111110";
          cntRight := (cntRight + 1) mod "111110";
        end if;
        
        seedLeft <= std_logic_vector(cntLeft);
        seedRight <= std_logic_vector(cntRight);
      end process;
    
    leftRandomGenerator: lsfr
      generic map(WL => 6)
      port map(clk => clk, rst => rstSync, ce => '1', ld => '1', seed => seedLeft, random => randomLeft);
      
    rightRandomGenerator: lsfr
      generic map(WL => 6)
      port map(clk => clk, rst => rstSync, ce => '1', ld => '1', seed => seedRight, random => randomRight);

    ------------------
    
    rst_n <= '1';
    pwdn  <= '0';

    xclkGenerator : freqSynthesizer
      generic map ( FREQ_KHZ => FREQ_KHZ, MULTIPLY => 1, DIVIDE => 4 )
      port map ( clkIn => clk, rdy => xclkRdy, clkOut => xclk );
    
    programmer : ov7670programmer
      generic map ( FREQ_KHZ => FREQ_KHZ, BAUDRATE => 400_000, DEV_ID => "0100001")
      port map ( clk  => clk, rdy => progRdy, sioc => sioc, siod => siod );
    
    rec <= progRdy and xclkRdy;
    
    videoIn: ov7670reader 
      port map ( clk => clk, rec => rec, x => wrX, y => wrY, dataRdy => wea(0), data => wrData, pClk => pClk, cvSync => cvSync, hRef => hRef, cData => cData );
     
    wrAddrCalculator: multAdd
      port map ( a => wrY(8 downto 1), b => std_logic_vector(to_unsigned(320, 9)), c => wrX(9 downto 1), subtract => '0', p => wrAddr, pcout => open);
  
    rdAddrCalculator: multAdd
      port map ( a => rdY(8 downto 1), b => std_logic_vector(to_unsigned(320, 9)), c => rdX(9 downto 1), subtract => '0', p => rdAddr, pcout => open);

    videoInMemory : frameBuffer 
      port map ( clka => clk, wea => wea, addra => wrAddr, dina => wrData, clkb => clk, addrb => rdAddr , doutb => rdData);

    screenInteface: vgaRefresher
      generic map ( FREQ_DIV => FREQ_DIV )
      port map ( clk => clk, line => lineAux, pixel => pixelAux, R => color(11 downto 8), G => color(7 downto 4), B => color(3 downto 0), hSync => hSync, vSync => vSync, RGB => RGB );
    
    rdY  <= lineAux(8 downto 0);
    rdX <= pixelAux;
    
    pixel <= unsigned(pixelAux(9 downto 2));
    line  <= unsigned(lineAux(9 downto 2));
    
    -- Setups all the colouring needed to represent the game
    fieldColouring:
    process (pixel, line, pixelAux, lineAux)
      type pointerRom is array(0 to BIRD_SIZE*BIRD_SIZE*BIRD_SIZE*BIRD_SIZE - 1) of natural range 0 to 4;
      constant rom: pointerRom := (
        0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,
        0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,
        0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,
        0,0,1,1,1,1,1,3,3,1,1,1,1,1,0,0,
        0,1,1,1,1,1,3,4,4,3,1,1,1,1,1,0,
        0,1,1,1,1,1,1,3,3,1,1,1,1,1,1,0,
        0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,
        0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,
        0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,
        0,0,0,0,0,0,2,2,0,0,1,1,0,0,0,0,
        0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      );
      variable xAddr : natural range 0 to BIRD_SIZE*BIRD_SIZE - 1;
      variable yAddr : natural range 0 to BIRD_SIZE*BIRD_SIZE - 1;
    begin
    
      color <= rdData when backgroundSync = '1' else (others => '0');

      -- Represent the middle wall
      if pixel = 79 or pixel = 80 then
        color <= "110011100000";
      end if;
      
      -- Represent the left wall
      if showLeftWall and (line >= yLeftWall and line < yLeftWall + HEIGHT_MOVING_WALLS)
        and ((pixel < xLeftWall) or (pixel >= xLeftWall + GAP_MOVING_WALLS and pixel < 79)) then
        color <= "111100000000";
      end if;
        
      -- Represent the right wall
      if showRightWall and (line >= yRightWall and line < yRightWall + HEIGHT_MOVING_WALLS) 
        and ((pixel >= 81 and pixel < xRightWall) or pixel >= xRightWall + GAP_MOVING_WALLS) then
        color <= "000000001111";
      end if;
      
      -- Represent the left bird
      if pixel >= xLeftBird and pixel < xLeftBird + BIRD_SIZE and line >= DEFAULT_Y_BIRDS and line < DEFAULT_Y_BIRDS + BIRD_SIZE then
        xAddr := to_integer(unsigned(pixelAux) - xLeftBird*BIRD_SIZE);
        yAddr := to_integer(unsigned(lineAux) - DEFAULT_Y_BIRDS*BIRD_SIZE);
        case rom(yAddr * BIRD_SIZE * BIRD_SIZE + xAddr) is
          when 0 => null;
          when 1 => color <= x"FF0";
          when 2 => color <= x"F60";
          when 3 => color <= x"FFF";
          when 4 => color <= x"000";
        end case;
      end if;
        

      -- Represent the right bird
      if pixel >= xRightBird and pixel < xRightBird + BIRD_SIZE and line >= DEFAULT_Y_BIRDS and line < DEFAULT_Y_BIRDS + BIRD_SIZE then
        xAddr := to_integer(unsigned(pixelAux) - xRightBird*BIRD_SIZE);
        yAddr := to_integer(unsigned(lineAux) - DEFAULT_Y_BIRDS*BIRD_SIZE);
        case rom(yAddr * BIRD_SIZE * BIRD_SIZE + xAddr) is
          when 0 => null;
          when 1 => color <= x"FF0";
          when 2 => color <= x"F60";
          when 3 => color <= x"FFF";
          when 4 => color <= x"000";
        end case;
      end if;
    end process;
    
    ------------------
    
    leftBird:
    process (clk)
      constant DEFAULT_X : natural := 39; 
    begin
      if rising_edge(clk) then
        if rstSync = '1' then
          xLeftBird <= to_unsigned( DEFAULT_X, 8 );
        else
          if move50 and not endLeftGame then
              -- mover izquierda
              if (zP and xLeftBird > 0) then
                xLeftBird <= xLeftBird - 1;
              -- mover derecha
              elsif (cP and xLeftBird + BIRD_SIZE < 79) then
                xLeftBird <= xLeftBird + 1;
              end if;
          end if;
        end if;
      end if;
    end process;

    rightBird:
    process (clk)
      constant DEFAULT_X : natural := 118;
    begin
      if rising_edge(clk) then
        if rstSync = '1' then
          xRightBird <= to_unsigned( DEFAULT_X, 8 );
        else
          if move50 and not endRightGame then
              -- mover izquierda
              if (bP and xRightBird > 81) then
                xRightBird <= xRightBird - 1;
              -- mover derecha
              elsif (mP and xRightBird + BIRD_SIZE < POINTSxLINE) then
                xRightBird <= xRightBird + 1; 
              end if;
          end if;
        end if;
      end if;
    end process;
    
    leftwall:
    process(clk)
      variable time_waiting : natural := 0;
     
      type states is ( s0, s1, s2, s3, s4 );
      variable state     : states := s0;
      variable cycles    : natural := ms2cycles(FREQ_KHZ, 100);
    begin
    
      endLeftGame <= false;
      showLeftWall <= true;
      if state = s3 then
        endLeftGame <= true;
        showLeftWall <= false;
      elsif state = s4 then
        showLeftWall <= false;
      elsif state = s0 then
        showLeftWall <= false;
      end if;
      
      if rising_edge(clk) then
        if rstSync = '1' then
          time_waiting := 0;
          counterLeft <= to_unsigned(0, 8);
          xLeftWall <= "00" & unsigned(randomLeft);
          yLeftWall <= to_unsigned(5, 8);
          state := s0;
        else
          case state is
              when s0 =>
                -- comienza el movimiento durante 1 ciclo
                if move60 and not endLeftGame then
                  xLeftWall <= "00" & unsigned(randomLeft);
                  yLeftWall <= to_unsigned(5, 8);
                  state := s1;
                  showLeftWall <= true;
                end if;
              when s1 => 
                if move60 then
                  yLeftWall <= yLeftWall + 1;
                  if yLeftWall + HEIGHT_MOVING_WALLS - 1 = DEFAULT_Y_BIRDS then
                    state := s2;
                  end if;
                end if;
              -- podria haber colision
              when s2 =>
                if xLeftWall < xLeftBird and xLeftWall + GAP_MOVING_WALLS > xLeftBird + BIRD_SIZE then
                  counterLeft <= counterLeft + 1;
                  soundEnable <= '1';
                  time_waiting := ms2cycles(FREQ_KHZ, 250 + to_integer(unsigned(randomLeft)) * 16);
                  state := s4;
                else 
                  state := s3;
                end if;
              -- we've lost, waiting for spc pressed
              when s3 =>
                if restart then
                  counterLeft <= to_unsigned(0, 8);
                  state := s0;
                end if;
              when s4 =>
                if (time_waiting > 0) then
                  time_waiting := time_waiting - 1;
                else 
                  state := s0;
                end if;
          end case;
          
          if (soundEnable = '1') then
            if (cycles = 0) then         
              cycles := ms2cycles(FREQ_KHZ, 300);
              soundEnable <= '0';
            else
              cycles := cycles - 1;
            end if;
          end if;
        end if;
      end if;
    end process;
    
    rightwall:
    process(clk)
      variable time_waiting : natural := 0;
      
      type states is ( s0, s1, s2, s3, s4 );
      variable state     : states := s0;
    begin
    
      endRightGame <= false;
      showRightWall <= true;
      if state = s3 then
        endRightGame <= true;
        showRightWall <= false;
      elsif state = s4 then
        showRightWall <= false;
      elsif state = s0 then
        showRightWall <= false;
      end if;
      
      if rising_edge(clk) then
        if rstSync = '1' then
          time_waiting := 0;
          counterRight <= to_unsigned(0, 8);
          xRightWall <= resize(unsigned(randomRight), 8) + to_unsigned(81, 8);
          yRightWall <= to_unsigned(5, 8);
          state := s0;
        else
          case state is
              -- comienza el movimiento durante 1 ciclo
              when s0 =>
                if move60 and not endRightGame then
                  xRightWall <= resize(unsigned(randomRight), 8) + to_unsigned(81, 8);
                  yRightWall <= to_unsigned(5, 8);
                  state := s1;
                  showRightWall <= true;
                end if;
              when s1 => 
                if move60 then
                  yRightWall <= yRightWall + 1;
                  if yRightWall + HEIGHT_MOVING_WALLS - 1 = DEFAULT_Y_BIRDS then
                    state := s2;
                  end if;
                end if;
              -- probable hit
              when s2 =>
                if xRightWall < xRightBird and xRightWall + GAP_MOVING_WALLS > xRightBird + BIRD_SIZE then
                  counterRight <= counterRight + 1;
                  time_waiting := ms2cycles(FREQ_KHZ, 250 + to_integer(unsigned(randomRight)) * 16);
                  state := s4;
                else 
                  state := s3;
                end if;
              when s3 =>
                if restart then
                  counterRight <= to_unsigned(0, 8);
                  state := s0;
                end if;
               when s4 =>
                if (time_waiting > 0) then
                  time_waiting := time_waiting - 1;
                else 
                  state := s0;
                end if;
          end case;
        end if;
      end if;
    end process;
end syn;