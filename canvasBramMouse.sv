`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.12.2024 19:06:33
// Design Name: 
// Module Name: canvasBramMouse
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module canvasBramMouse(
    input logic CLK100MHZ,
    input logic btnC,
    input logic btnU,
    input logic btnL,
    input logic btnR,
    input logic btnD,
    input logic PS2Clk,
    input logic PS2Data,
    input logic [15:0] sw,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    output logic Hsync,
    output logic Vsync
    );
        
    function automatic int abs(int value);
        return (value < 0) ? -value : value;
    endfunction

    // Parameters
    parameter N = 1;
    parameter rowNum = 480;
    parameter columnNum = 640;

    // VGA Timing and Internal Signals
    logic PCLK;
    logic [10:0] horizontalTiming;
    logic [10:0] verticalTiming;
    int signed counter;
    logic [2:0] clockCounter;

    int signed  mouseRow;
    int signed  mouseColumn;

    logic [18:0] addra;
    logic [18:0] addrb;
    logic [2:0] doutb;
    logic wea;

    // Instantiate BRAM
    blk_mem_gen_0 your_instance_name (
  .clka(CLK100MHZ),    // input wire clka
  .wea(wea),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [18 : 0] addra
  .dina(sw[2:0]),    // input wire [2 : 0] dina
  .clkb(CLK100MHZ),    // input wire clkb
  .addrb(addrb),  // input wire [18 : 0] addrb
  .doutb(doutb)  // output wire [2 : 0] doutb
);

    // PS/2 Mouse Interface
    logic [7:0] o_x, o_y;
    logic o_x_ov, o_y_ov, o_x_sign, o_y_sign;
    logic o_r_click, o_l_click, o_valid;

    ps2_mouse dut (
        .i_clk(PCLK),
        .i_reset(btnC),
        .i_PS2Data(PS2Data),
        .i_PS2Clk(PS2Clk),
        .o_x(o_x),
        .o_x_ov(o_x_ov),
        .o_x_sign(o_x_sign),
        .o_y(o_y),
        .o_y_ov(o_y_ov),
        .o_y_sign(o_y_sign),
        .o_r_click(o_r_click),
        .o_l_click(o_l_click),
        .o_valid(o_valid)
    );

    // Clock Divider for PCLK
   
    // Initial Block
    initial begin
        vgaRed = 0;
        vgaGreen = 0;
        vgaBlue = 0;
        horizontalTiming = 0;
        verticalTiming = 0;
        Hsync = 1;
        Vsync = 1;
        mouseRow = 300;
        mouseColumn = 300;
        counter = 0;
        clockCounter = 0;
        PCLK = 0;
    end

    // VGA Output Signals
    logic red;
    logic green;
    logic blue;

    assign vgaRed = red * 15;
    assign vgaBlue = blue * 15;
    assign vgaGreen = green * 15;

    logic ready;
    
    parameter divider = 128;
    
    always @(posedge PCLK)begin
        if(horizontalTiming == 799)
            addrb <= (verticalTiming + 1) * columnNum + 0;
        else
            addrb <= (verticalTiming) * columnNum + horizontalTiming + 1;        
        
        Hsync <= ~(horizontalTiming >= 656 && horizontalTiming <= 751);
        Vsync <= ~(verticalTiming >= 490 && verticalTiming <= 491);

        // Timing Updates
        if (horizontalTiming == 799) begin
            horizontalTiming <= 0;
            verticalTiming <= (verticalTiming == 524) ? 0 : verticalTiming + 1;
        end 
        else begin
            horizontalTiming <= horizontalTiming + 1;
        end
        // Active Display Area
        if ((horizontalTiming < columnNum) && (verticalTiming < rowNum)) begin
            if ((abs(horizontalTiming / N - mouseColumn) <= 10 && verticalTiming / N == mouseRow) || (abs(verticalTiming / N - mouseRow) <= 10 && horizontalTiming / N == mouseColumn)) begin
                {red, green, blue} <= sw[2:0]; // Cursor color
            end 
            else begin
                {red, green, blue} <= doutb;  // BRAM pixel data
            end 
        end 
        else begin
            {red, green, blue} <= 0; // Black outside active area
        end  
             
    end
    
    always @(posedge CLK100MHZ) begin
        if (clockCounter == 1) begin
            clockCounter = 0;
            PCLK = ~PCLK;
        end else begin
            clockCounter = clockCounter + 1;
        end
        
        if(counter == 9) begin
                if (o_valid) begin
                    if (!o_x_ov) begin
                        if (o_x_sign) 
                            mouseColumn <= (mouseColumn > o_x / divider) ? mouseColumn - o_x / divider : 0;
                        else 
                            mouseColumn <= (mouseColumn + o_x / divider <= columnNum - 1) ? mouseColumn + o_x / divider : columnNum - 1;
                    end
            
                    if (!o_y_ov) begin
                        if (o_y_sign) 
                            mouseRow <= (mouseRow + o_y / divider <= rowNum - 1) ? mouseRow + o_y / divider : rowNum - 1;
                        else 
                            mouseRow <= (mouseRow > o_y / divider) ? mouseRow - o_y / divider : 0;
                    end
                
                end    
                    
                wea <= 0;    
                counter <= 0;          
                    
        end
        else if (counter >= 0 && counter <= 8) begin
            if(o_l_click) begin
                if(sw[15]) begin   
                    automatic int signed i = (counter) / 3 - 1; // Row offset: -1, 0, 1
                    automatic int signed j = (counter) % 3 - 1; // Column offset: -1, 0, 1     
                    if ((mouseRow + i >= 0 && mouseRow + i < rowNum) && (mouseColumn + j >= 0 && mouseColumn + j < columnNum)) begin
                        addra <= (mouseRow + i) * columnNum + (mouseColumn + j);
                        wea <= 1;
                    end
                end
                else begin
                    if(mouseRow >= 0 && mouseRow < rowNum && mouseColumn >= 0 && mouseColumn < columnNum)begin
                        addra <= mouseRow * columnNum + mouseColumn;
                        wea <= 1;
                    end        
                end
            end        
            else
                wea <= 0;       
                  
            counter <= counter + 1; 
        end
        else begin
            wea <= 0;
            counter <= counter + 1; 
        end         
    end
endmodule

    
