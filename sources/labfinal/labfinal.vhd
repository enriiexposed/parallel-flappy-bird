/*
Proyecto final de DAS

Realizado por Enrique Rï¿½os

Flappy Bird Doble Concurrente

Usando el estÃ¡ndar VHDL'08
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
    -- 8 segments side
    segs_n   : out std_logic_vector(7 downto 0);
    an_n     : out std_logic_vector(3 downto 0);
    
    -- Keyboard side
    ps2Clk   : in  std_logic;
    ps2Data  : in  std_logic;
    -- VGA side
    hSync    : out  std_logic;
    vSync    : out  std_logic;
    RGB      : out  std_logic_vector(11 downto 0)
  );
end labfinal;

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of labfinal is
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
  signal rstSync : std_logic;
  signal data: std_logic_vector(7 downto 0);
  signal dataRdy: std_logic;

  signal color          : std_logic_vector(11 downto 0);
  signal move, endLeftGame, endRightGame, showLeftWall, showRightWall, restart : boolean;
  
  signal lineAux, pixelAux : std_logic_vector(9 downto 0);  
  signal line, pixel    : unsigned(7 downto 0);

  signal random   : std_logic_vector(5 downto 0);

  -- Registers
  signal xLeftWall      : unsigned(7 downto 0) := to_unsigned(30, 8);
  signal yLeftWall      : unsigned(7 downto 0) := to_unsigned(5, 8);
  
  signal xRightWall     : unsigned(7 downto 0) := to_unsigned(118, 8);
  signal yRightWall     : unsigned(7 downto 0) := to_unsigned(5, 8);
  
  signal xLeftBird      : unsigned(7 downto 0) := to_unsigned(39, 8);
  signal xRightBird     : unsigned(7 downto 0) := to_unsigned(118, 8);

  signal counterLeft :  unsigned(7 downto 0) := to_unsigned(0, 8);
  signal counterRight : unsigned(7 downto 0) := to_unsigned(0, 8); 
  
  signal zP, cP, bP, mP, spcP: boolean := false;
  
  begin

    resetSynchronizer : synchronizer
      generic map(STAGES  => 2, XPOL => '0')
      port map(clk => clk, x => rst, xSync => rstSync);
    
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
      constant CYCLES : natural := hz2cycles(FREQ_KHZ, 50);
      variable count  : natural range 0 to CYCLES-1 := 0;
    begin
      if rising_edge(clk) then
          if rstSync = '1' then
              count := 0;
              move <= false;
          else
            move <= false;  
            if endLeftGame and endRightGame then
              count := 0;
            else
              count := count + 1 mod CYCLES;
              if count = CYCLES - 1 then
                move <= true;
              end if;
            end if;
          end if;
      end if;
    end process;
    
    ------------------
    
    randomGenerator: lsfr
      generic map(WL => 6)
      port map(clk => clk, rst => rstSync, ce => '1', ld => clk, seed => random, random => random);

    ------------------

    screenInteface: vgaRefresher
      generic map ( FREQ_DIV => FREQ_DIV )
      port map ( clk => clk, line => lineAux, pixel => pixelAux, R => color(11 downto 8), G => color(7 downto 4), B => color(3 downto 0), hSync => hSync, vSync => vSync, RGB => RGB );
    
    pixel <= unsigned(pixelAux(9 downto 2));
    line  <= unsigned(lineAux(9 downto 2));
    
    -- Setups all the colouring needed to represent the game
    fieldColouring:
    process (pixel, line)
    begin
      color <= (others => '0');

      -- Represent the middle wall
      if pixel = 79 or pixel = 80 then
        color <= "110011100000";
        
      -- Represent the left bird
      elsif pixel >= xLeftBird and pixel < xLeftBird + BIRD_SIZE and line >= DEFAULT_Y_BIRDS and line < DEFAULT_Y_BIRDS + BIRD_SIZE then
        color <= "111111111111";

      -- Represent the right bird
      elsif pixel >= xRightBird and pixel < xRightBird + BIRD_SIZE and line >= DEFAULT_Y_BIRDS and line < DEFAULT_Y_BIRDS + BIRD_SIZE then
        color <= "111111111111";
      
      -- Represent the left wall
      elsif line >= yLeftWall and line < yLeftWall + HEIGHT_MOVING_WALLS
        and ((pixel < xLeftWall) or (pixel >= xLeftWall + GAP_MOVING_WALLS and pixel < 79)) then
        color <= "111100000000";
        
      -- Represent the right wall
      elsif (line >= yRightWall and line < yRightWall + HEIGHT_MOVING_WALLS) 
        and ((pixel >= 81 and pixel < xRightWall) or pixel >= xRightWall + GAP_MOVING_WALLS) then
        color <= "000000001111";    
      
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
          if move then
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
      constant DEFAULT_X : natural := 119; 
    begin
      if rising_edge(clk) then
        if rstSync = '1' then
          xRightBird <= to_unsigned( 118, 8 );
        else
          if move then
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
      type states is ( s0, s1, s2, s3 );
      variable state     : states := s0;
    begin
      if rising_edge(clk) then
        if rstSync = '1' then
          counterLeft <= to_unsigned(0, 8);
          xLeftWall <= "00" & unsigned(random);
          yLeftWall <= to_unsigned(5, 8);
          state := s0;
        else
        
          endLeftGame <= false;
          showLeftWall <= true;
            
          if (state = s3) then
            endLeftGame <= true;
            showLeftWall <= false;
          end if;
        
          case state is
          when s0 =>
            -- comienza el movimiento durante 1 ciclo
            if move and not endLeftGame then
              xLeftWall <= "00" & unsigned(random);
              yLeftWall <= to_unsigned(5, 8);
              state := s1;
            end if;
          when s1 => 
            if move then
              yLeftWall <= yLeftWall + 1;
              if yLeftWall + HEIGHT_MOVING_WALLS - 1 = DEFAULT_Y_BIRDS then
                state := s2;
              end if;
            end if;
          -- podria haber colision
          when s2 =>
            if xLeftWall < xLeftBird and xLeftWall + GAP_MOVING_WALLS > xLeftBird + BIRD_SIZE then
              counterLeft <= counterLeft + 1;
              state := s0;
            else 
              state := s3;
            end if;
          when s3 =>
            if restart then
              counterLeft <= to_unsigned(0, 8);
              state := s0;
            end if;
          end case;
        end if;
      end if;
    end process;
    
    rightwall:
    process(clk)
      type states is ( s0, s1, s2, s3 );
      variable state     : states := s0;
    begin
      if rising_edge(clk) then
        if rstSync = '1' then
          counterRight <= to_unsigned(0, 8);
          xRightWall <= resize(unsigned(random), 8) + to_unsigned(81, 8);
          yRightWall <= to_unsigned(5, 8);
          state := s0;
        else
          endRightGame <= false;
          showRightWall <= true;
          if (state = s3) then
            endRightGame <= true;
            showRightWall <= false;
          end if;
        
          case state is
          when s0 =>
            -- comienza el movimiento durante 1 ciclo
            if move and not endRightGame then
              xRightWall <= resize(unsigned(random), 8) + to_unsigned(81, 8);
              yRightWall <= to_unsigned(5, 8);
              state := s1;
            end if;
          when s1 => 
            if move then
              yRightWall <= yRightWall + 1;
              if yRightWall + HEIGHT_MOVING_WALLS - 1 = DEFAULT_Y_BIRDS then
                state := s2;
              end if;
            end if;
          -- podria haber colisión
          when s2 =>
            if xRightWall < xRightBird and xRightWall + GAP_MOVING_WALLS > xRightBird + BIRD_SIZE then
              counterRight <= counterRight + 1;
              state := s0;
            else 
              state := s3;
            end if;
          when s3 =>
            if restart then
              counterRight <= to_unsigned(0, 8);
              state := s0;
            end if;
          end case;
        end if;
      end if;
    end process;
end syn;