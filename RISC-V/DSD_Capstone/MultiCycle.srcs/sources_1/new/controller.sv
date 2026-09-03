`timescale 1ns / 1ps

module controller(
    input logic clk,
    input logic reset,
    
    input logic [6:0] op,
    input logic [2:0] funct3,
    input logic funct7b5, 
    input logic Zero,    
    
    output logic PCWrite,
    output logic AdrSrc,
    output logic MemWrite,
    output logic IRWrite,
    output logic RegWrite,
    output logic [2:0] ImmSrc,    
    output logic [1:0] ALUSrcA,
    output logic [1:0] ALUSrcB,
    output logic [3:0] ALUControl,
    output logic [1:0] ResultSrc
);

    typedef enum logic [3:0] {
        FETCH = 4'd0,
        DECODE = 4'd1,
        MEMADR = 4'd2,
        MEMREAD  = 4'd3,
        MEMWB = 4'd4,
        MEMWRITE = 4'd5,
        EXECUTER = 4'd6,
        EXECUTEI = 4'd7,
        ALUWB = 4'd8,
        JAL = 4'd9,
        BEQ = 4'd10,
        EXEC_LUI = 4'd11    
    } statetype;

    statetype state, next_state;

    always_ff @(posedge clk) begin
        if (reset) state <= FETCH;
        else       state <= next_state;
    end

    always_comb begin
        case (state)
            FETCH:    next_state = DECODE;
            
            DECODE: begin
                case (op)
                    7'b0000011: next_state = MEMADR;   // lw
                    7'b0100011: next_state = MEMADR;   // sw
                    7'b0110011: next_state = EXECUTER; // R-type
                    7'b0010011: next_state = EXECUTEI; // I-type ALU
                    7'b1101111: next_state = JAL;      // jal
                    7'b1100011: next_state = BEQ;      // beq/bne
                    7'b0110111: next_state = EXEC_LUI; // lui
                    default:    next_state = FETCH;    
                endcase
            end
            
            MEMADR: next_state = (op == 7'b0000011) ? MEMREAD : MEMWRITE;
            MEMREAD: next_state = MEMWB;
            MEMWB: next_state = FETCH;
            MEMWRITE: next_state = FETCH;
            EXECUTER: next_state = ALUWB;
            EXECUTEI: next_state = ALUWB;
            EXEC_LUI: next_state = ALUWB; 
            ALUWB: next_state = FETCH;
            JAL: next_state = FETCH;
            BEQ: next_state = FETCH;
            default:  next_state = FETCH;
        endcase
    end

    logic PCUpdate, Branch, BranchCond;
    logic [1:0] ALUOp;
    
    always_comb begin
        if (funct3 == 3'b000)      BranchCond = Zero;       // BEQ
        else if (funct3 == 3'b001) BranchCond = ~Zero;      // BNE
        else                       BranchCond = 1'b0;
    end
    
    assign PCWrite = PCUpdate | (Branch & BranchCond);

    always_comb begin
        PCUpdate = 0; AdrSrc   = 0; MemWrite = 0; IRWrite = 0;
        RegWrite = 0; ALUSrcA  = 2'b00; ALUSrcB = 2'b00; 
        ResultSrc = 2'b00; Branch = 0; ALUOp = 2'b00;

        case (state)
            FETCH: begin
                AdrSrc = 0;      
                IRWrite = 1;      
                ALUSrcA = 2'b00;  
                ALUSrcB = 2'b01;  
                ALUOp = 2'b00;  
                ResultSrc= 2'b10;  
                PCUpdate = 1;      
            end
            DECODE: begin
                ALUSrcA = 2'b01;  
                ALUSrcB = 2'b10;  
                ALUOp = 2'b00;  
            end
            MEMADR: begin
                ALUSrcA = 2'b10;  
                ALUSrcB = 2'b10;  
                ALUOp = 2'b00;  
            end
            MEMREAD: begin
                ResultSrc= 2'b00;  
                AdrSrc = 1;      
            end
            MEMWB: begin
                ResultSrc= 2'b01;  
                RegWrite = 1;
            end
            MEMWRITE: begin
                ResultSrc= 2'b00;  
                AdrSrc = 1;      
                MemWrite = 1;      
            end
            EXECUTER: begin
                ALUSrcA = 2'b10;  
                ALUSrcB = 2'b00;  
                ALUOp = 2'b10;  
            end
            EXECUTEI: begin
                ALUSrcA = 2'b10;  
                ALUSrcB = 2'b10;  
                ALUOp = 2'b10;  
            end
            EXEC_LUI: begin
                ALUSrcA = 2'b11;  
                ALUSrcB = 2'b10;  
                ALUOp = 2'b00;  
            end
            ALUWB: begin
                ResultSrc= 2'b00;  
                RegWrite = 1;
            end
            BEQ: begin
                ALUSrcA = 2'b10;  
                ALUSrcB = 2'b00;  
                ALUOp = 2'b01;  
                ResultSrc= 2'b00;  
                Branch = 1;      
            end
            JAL: begin
                ALUSrcA = 2'b01;  
                ALUSrcB = 2'b10;  
                ALUOp = 2'b00;  
                ResultSrc= 2'b00;  
                PCUpdate = 1;      
            end
        endcase
    end

    always_comb begin
        case (op)
            7'b0100011: ImmSrc = 3'b001; // sw 
            7'b1100011: ImmSrc = 3'b010; // beq/bne 
            7'b1101111: ImmSrc = 3'b011; // jal 
            7'b0110111: ImmSrc = 3'b100; // lui 
            default: ImmSrc = 3'b000; // lw, I-type
        endcase
    end

    always_comb begin
        if (ALUOp == 2'b00) begin
            ALUControl = 4'b0000; 
        end else if (ALUOp == 2'b01) begin
            ALUControl = 4'b0001; 
        end else begin
            case (funct3)
                3'b000: begin
                    if ({op[5], funct7b5} == 2'b11) ALUControl = 4'b0001; 
                    else                            ALUControl = 4'b0000; 
                end
                3'b111: ALUControl = 4'b0010; 
                3'b110: ALUControl = 4'b0011; 
                3'b100: ALUControl = 4'b0100; 
                3'b001: ALUControl = 4'b0101; 
                3'b101: ALUControl = 4'b0110; 
                default: ALUControl = 4'b0000;
            endcase
        end
    end
endmodule