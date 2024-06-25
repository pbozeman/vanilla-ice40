`timescale 1ns / 1ps

module solder_chk_tb;

  reg  clk = 1'b0;

  wire led1;
  wire led2;

  wire PIN3;
  wire PIN4;
  wire PIN7;
  wire PIN8;
  wire PIN9;
  wire PIN10;
  wire PIN11;
  wire PIN12;
  wire PIN15;
  wire PIN16;
  wire PIN17;
  wire PIN18;
  wire PIN19;
  wire PIN20;
  wire PIN22;
  wire PIN23;
  wire PIN24;
  wire PIN25;
  wire PIN26;
  wire PIN28;
  wire PIN29;
  wire PIN31;
  wire PIN32;
  wire PIN33;
  wire PIN34;
  wire PIN37;
  wire PIN38;
  wire PIN39;
  wire PIN41;
  wire PIN42;
  wire PIN43;
  wire PIN44;
  wire PIN45;
  wire PIN47;
  wire PIN48;
  wire PIN49;
  wire PIN52;
  wire PIN55;
  wire PIN56;
  wire PIN60;
  wire PIN61;
  wire PIN62;
  wire PIN63;
  wire PIN64;
  wire PIN67;
  wire PIN68;
  wire PIN70;
  wire PIN71;
  wire PIN73;
  wire PIN74;
  wire PIN75;
  wire PIN76;
  wire PIN78;
  wire PIN79;
  wire PIN80;
  wire PIN81;
  wire PIN82;
  wire PIN83;
  wire PIN84;
  wire PIN85;
  wire PIN87;
  wire PIN88;
  wire PIN90;
  wire PIN91;
  wire PIN93;
  wire PIN94;
  wire PIN95;
  wire PIN96;
  wire PIN97;
  wire PIN98;
  wire PIN99;
  wire PIN101;
  wire PIN102;
  wire PIN104;
  wire PIN105;
  wire PIN106;
  wire PIN107;
  wire PIN110;
  wire PIN112;
  wire PIN113;
  wire PIN114;
  wire PIN115;
  wire PIN116;
  wire PIN117;
  wire PIN118;
  wire PIN119;
  wire PIN120;
  wire PIN121;
  wire PIN122;
  wire PIN124;
  wire PIN125;
  wire PIN128;
  wire PIN129;
  wire PIN130;
  wire PIN134;
  wire PIN135;
  wire PIN136;
  wire PIN137;
  wire PIN138;
  wire PIN139;
  wire PIN141;
  wire PIN142;
  wire PIN143;
  wire PIN144;

  wire error;

  solder_chk_top uut (
      .clk_i(clk),

      .led1_o(led1),
      .led2_o(led2),

      .PIN3  (PIN3),
      .PIN4  (PIN4),
      .PIN7  (PIN7),
      .PIN8  (PIN8),
      .PIN9  (PIN9),
      .PIN10 (PIN10),
      .PIN11 (PIN11),
      .PIN12 (PIN12),
      .PIN15 (PIN15),
      .PIN16 (PIN16),
      .PIN17 (PIN17),
      .PIN18 (PIN18),
      .PIN19 (PIN19),
      .PIN20 (PIN20),
      .PIN22 (PIN22),
      .PIN23 (PIN23),
      .PIN24 (PIN24),
      .PIN25 (PIN25),
      .PIN26 (PIN26),
      .PIN28 (PIN28),
      .PIN29 (PIN29),
      .PIN31 (PIN31),
      .PIN32 (PIN32),
      .PIN33 (PIN33),
      .PIN34 (PIN34),
      .PIN37 (PIN37),
      .PIN38 (PIN38),
      .PIN39 (PIN39),
      .PIN41 (PIN41),
      .PIN42 (PIN42),
      .PIN43 (PIN43),
      .PIN44 (PIN44),
      .PIN45 (PIN45),
      .PIN47 (PIN47),
      .PIN48 (PIN48),
      .PIN49 (PIN49),
      .PIN52 (PIN52),
      .PIN55 (PIN55),
      .PIN56 (PIN56),
      .PIN60 (PIN60),
      .PIN61 (PIN61),
      .PIN62 (PIN62),
      .PIN63 (PIN63),
      .PIN64 (PIN64),
      .PIN67 (PIN67),
      .PIN68 (PIN68),
      .PIN70 (PIN70),
      .PIN71 (PIN71),
      .PIN73 (PIN73),
      .PIN74 (PIN74),
      .PIN75 (PIN75),
      .PIN76 (PIN76),
      .PIN78 (PIN78),
      .PIN79 (PIN79),
      .PIN80 (PIN80),
      .PIN81 (PIN81),
      .PIN82 (PIN82),
      .PIN83 (PIN83),
      .PIN84 (PIN84),
      .PIN85 (PIN85),
      .PIN87 (PIN87),
      .PIN88 (PIN88),
      .PIN90 (PIN90),
      .PIN91 (PIN91),
      .PIN93 (PIN93),
      .PIN94 (PIN94),
      .PIN95 (PIN95),
      .PIN96 (PIN96),
      .PIN97 (PIN97),
      .PIN98 (PIN98),
      .PIN99 (PIN99),
      .PIN101(PIN101),
      .PIN102(PIN102),
      .PIN104(PIN104),
      .PIN105(PIN105),
      .PIN106(PIN106),
      .PIN107(PIN107),
      .PIN110(PIN110),
      .PIN112(PIN112),
      .PIN113(PIN113),
      .PIN114(PIN114),
      .PIN115(PIN115),
      .PIN116(PIN116),
      .PIN117(PIN117),
      .PIN118(PIN118),
      .PIN119(PIN119),
      .PIN120(PIN120),
      .PIN121(PIN121),
      .PIN122(PIN122),
      .PIN124(PIN124),
      .PIN125(PIN125),
      .PIN128(PIN128),
      .PIN129(PIN129),
      .PIN130(PIN130),
      .PIN134(PIN134),
      .PIN135(PIN135),
      .PIN136(PIN136),
      .PIN137(PIN137),
      .PIN138(PIN138),
      .PIN139(PIN139),
      .PIN141(PIN141),
      .PIN142(PIN142),
      .PIN143(PIN143),
      .PIN144(PIN144)
  );

  // clock generator
  always #1 clk = ~clk;

  initial begin
    $dumpfile(".build/solder_chk.vcd");
    $dumpvars(0, uut);

    // Run the simulation for 2 ms (2000 µs)
    #2000000;

    $finish;
  end

endmodule

