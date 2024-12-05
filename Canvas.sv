`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.11.2024 01:25:16
// Design Name: 
// Module Name: Canvas
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

module Canvas(
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
     
    logic PCLK;    
          
    parameter N = 4;
    
    parameter rowNum = 30;
    parameter columnNum = 40;
    
    clk_wiz_0 instance_name
   (
    // Clock out ports
    .PCLK(PCLK),     // output PCLK
    // Status and control signals
    .reset(0), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .CLK100MHZ(CLK100MHZ)      // input CLK100MHZ
);
    
    logic [5:0] canvasMem [rowNum-1:0] [columnNum-1:0];
    
    logic [10:0] horizontalTiming;
    logic [10:0] verticalTiming;
    
    logic [10:0] mouseRow;
    logic [10:0] mouseColumn;
    
    logic [30:0] counter;
    logic [30:0] counter2;
    
    logic leftClick;
     
    logic xDirection;
    logic yDirection;
     
    logic [7:0] xSpeed;
    logic [7:0] ySpeed;
    
    
    initial begin
       for (int i = 0; i < rowNum ; i++) begin
            for(int j = 0; j < columnNum; j++)
                canvasMem [i] [j] = '1;
       end
       
       vgaRed = 0;
       vgaGreen = 0;
       vgaBlue = 0;
       
       horizontalTiming = 0;
       verticalTiming = 0;
       
       Hsync = 1;
       Vsync = 1;
       
       mouseRow = 0;
       mouseColumn = 0;
       
       counter = 0;
       counter2 = 0;
       
       leftClick = 0;
       
       xDirection = 0;
       yDirection = 0;
       
       xSpeed = 0;
       ySpeed = 0;
       
    end    
    
  
    always_ff @(posedge PCLK) begin
        if (horizontalTiming == 799) begin  
            horizontalTiming <= 0;
            verticalTiming <= (verticalTiming == 524) ? 0 : verticalTiming + 1;  
        end 
        else begin
            horizontalTiming <= horizontalTiming + 1;
        end
        
        Hsync <= ~(horizontalTiming >= 655 && horizontalTiming <= 750);  
        Vsync <= ~(verticalTiming >= 489 && verticalTiming <= 490);  
       
        if((horizontalTiming <= 639 && verticalTiming <= 479))
            if(horizontalTiming >> N != mouseColumn | verticalTiming >> N != mouseRow)
                {vgaRed[3:2],vgaGreen[3:2],vgaBlue[3:2]} <= canvasMem[verticalTiming>>N][horizontalTiming>>N];
            else
                {vgaRed[3:2],vgaGreen[3:2],vgaBlue[3:2]} <= sw[5:0];    
        else
            {vgaRed[3:2],vgaGreen[3:2],vgaBlue[3:2]} <= 0;        
        
    end

    
    
//    always @(posedge PCLK) begin
//        if(counter == 2520000) begin
        
//            if(btnR) 
//                if(mouseColumn >= 0 && mouseColumn <= columnNum-2)
//                    mouseColumn <= mouseColumn + 1;
                    
//            if(btnL) 
//                if(mouseColumn >= 1 && mouseColumn <= columnNum-1)
//                    mouseColumn <= mouseColumn - 1;
                    
//            if(btnD)        
//                if(mouseRow >= 0 && mouseRow <= rowNum-2)
//                    mouseRow <= mouseRow + 1;   
                    
//            if(btnU)        
//                if(mouseRow >= 1 && mouseRow <= rowNum-1)
//                    mouseRow <= mouseRow - 1; 
        
            
//            if(btnC)
//                if(sw[15]) begin
//                    for(int i = -1; i < 2; i++) 
//                        for(int j = -1; j < 2; j++) 
//                            //if(mouseRow+i >= 0 & mouseRow+i < rowNum & mouseColumn + j >= 0 & mouseColumn < columnNum)
//                                canvasMem [mouseRow+i] [mouseColumn+j] <= sw[5:0];   
//                end
                    
//                else
//                    canvasMem [mouseRow] [mouseColumn] <= sw[5:0];
            
//            counter <= 0;
//        end
        
        
//        else 
//            counter <= counter + 1;        
        
//    end
    
     always @(posedge PS2Clk) begin
           if(counter == 32) begin
                counter <= 0;
                
                            if(xDirection) begin
                                if(mouseColumn - xSpeed > 0)
                                    mouseColumn <= mouseColumn - xSpeed;
                                else
                                    mouseColumn <= 0;    
                            end
                                   
                            else begin
                                if(mouseColumn + xSpeed < columnNum)
                                    mouseColumn <= mouseColumn + xSpeed;
                                else
                                    mouseColumn <= columnNum - 1;  
                            end
                            
                            if(yDirection) begin
                                if(mouseRow + ySpeed < rowNum)
                                    mouseRow <= mouseRow + ySpeed;
                                else
                                    mouseRow <= rowNum - 1;                 
                            end
                                   
                            else begin
                                 if(mouseRow - ySpeed > 0)
                                    mouseRow <= mouseRow - ySpeed;
                                else
                                    mouseRow <= 0; 
                            end
                            
                            if(leftClick)
                                if(sw[15]) begin
                                    for(int i = -1; i < 2; i++) 
                                        for(int j = -1; j < 2; j++) 
                //if(mouseRow+i >= 0 & mouseRow+i < mouseRow & mouseColumn + j >= 0 & mouseColumn < mouseColumn)
                                                canvasMem [mouseRow+i] [mouseColumn+j] <= sw[5:0];   
                                end
                                    
                             else
                                    canvasMem [mouseRow] [mouseColumn] <= sw[5:0];
                
                
                  
           end     
           else 
                counter <= counter + 1;       
     end
     

  
endmodule
