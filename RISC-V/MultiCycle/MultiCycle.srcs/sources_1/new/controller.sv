`timescale 1ns / 1ps



module controller(
    input  logic       clk,
    input  logic       reset,
    
    // Instruction fields coming from the Datapath's `Instr` register
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7b5, // Bit 30 of the instruction
    input  logic       Zero,     // From the ALU
    
    // Control signals going to the Datapath
    output logic       PCWrite,
    output logic       AdrSrc,
    output logic       MemWrite,
    output logic       IRWrite,
    output logic       RegWrite,
    output logic [1:0] ImmSrc,
    output logic [1:0] ALUSrcA,
    output logic [1:0] ALUSrcB,
    output logic [3:0] ALUControl,
    output logic [1:0] ResultSrc
);

    // 1. MAIN FSM STATES
    typedef enum logic [3:0] {
        FETCH    = 4'd0,
        DECODE   = 4'd1,
        MEMADR   = 4'd2,
        MEMREAD  = 4'd3,
        MEMWB    = 4'd4,
        MEMWRITE = 4'd5,
        EXECUTER = 4'd6,
        EXECUTEI = 4'd7,
        ALUWB    = 4'd8,
        JAL      = 4'd9,
        BEQ      = 4'd10
    } statetype;

    statetype state, next_state;

    // FSM State Register
    always_ff @(posedge clk) begin
        if (reset) state <= FETCH;
        else       state <= next_state;
    end

    // 2. FSM NEXT STATE LOGIC
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
                    7'b1100011: next_state = BEQ;      // beq
                    default:    next_state = FETCH;    // Error catch
                endcase
            end
            
            MEMADR: begin
                if (op == 7'b0000011) next_state = MEMREAD;  // lw
                else                  next_state = MEMWRITE; // sw
            end
            
            MEMREAD:  next_state = MEMWB;
            MEMWB:    next_state = FETCH;
            MEMWRITE: next_state = FETCH;
            EXECUTER: next_state = ALUWB;
            EXECUTEI: next_state = ALUWB;
            ALUWB:    next_state = FETCH;
            JAL:      next_state = FETCH;
            BEQ:      next_state = FETCH;
            
            default:  next_state = FETCH;
        endcase
    end

    // 3. FSM OUTPUT LOGIC & ALU DECODER
    logic PCUpdate, Branch;
    logic [1:0] ALUOp;
    
    // Combine Branch and Zero flag for conditional PC writing
    assign PCWrite = PCUpdate | (Branch & Zero);

    always_comb begin
        // Default all signals to 0 to prevent latches
        PCUpdate  = 0; AdrSrc   = 0; MemWrite = 0; IRWrite = 0;
        RegWrite  = 0; ALUSrcA  = 2'b00; ALUSrcB = 2'b00; 
        ResultSrc = 2'b00; Branch = 0; ALUOp = 2'b00;

        case (state)
            FETCH: begin
                AdrSrc   = 0;      // Read from PC
                IRWrite  = 1;      // Save to Instr Reg
                ALUSrcA  = 2'b00;  // PC
                ALUSrcB  = 2'b01;  // + 4
                ALUOp    = 2'b00;  // Add
                ResultSrc= 2'b10;  // ALUResult
                PCUpdate = 1;      // PC = PC + 4
            end
            DECODE: begin
                ALUSrcA  = 2'b01;  // OldPC
                ALUSrcB  = 2'b10;  // ImmExt
                ALUOp    = 2'b00;  // Add (Target address prep)
            end
            MEMADR: begin
                ALUSrcA  = 2'b10;  // A (Rs1)
                ALUSrcB  = 2'b10;  // ImmExt
                ALUOp    = 2'b00;  // Add (Base + Offset)
            end
            MEMREAD: begin
                ResultSrc= 2'b00;  // ALUOut
                AdrSrc   = 1;      // Address comes from ALU
            end
            MEMWB: begin
                ResultSrc= 2'b01;  // Data from memory
                RegWrite = 1;
            end
            MEMWRITE: begin
                ResultSrc= 2'b00;  // ALUOut
                AdrSrc   = 1;      // Address comes from ALU
                MemWrite = 1;      // Write to memory
            end
            EXECUTER: begin
                ALUSrcA  = 2'b10;  // A (Rs1)
                ALUSrcB  = 2'b00;  // B (Rs2)
                ALUOp    = 2'b10;  // Decode funct3/7
            end
            EXECUTEI: begin
                ALUSrcA  = 2'b10;  // A (Rs1)
                ALUSrcB  = 2'b10;  // ImmExt
                ALUOp    = 2'b10;  // Decode funct3/7
            end
            ALUWB: begin
                ResultSrc= 2'b00;  // ALUOut
                RegWrite = 1;
            end
            BEQ: begin
                ALUSrcA  = 2'b10;  // A (Rs1)
                ALUSrcB  = 2'b00;  // B (Rs2)
                ALUOp    = 2'b01;  // Subtract
                ResultSrc= 2'b00;  // ALUOut (Target address)
                Branch   = 1;      // PCUpdate if Zero=1
            end
            JAL: begin
                ALUSrcA  = 2'b01;  // OldPC
                ALUSrcB  = 2'b10;  // ImmExt
                ALUOp    = 2'b00;  // Add (Calculate Target)
                ResultSrc= 2'b00;  // ALUOut
                PCUpdate = 1;      // Jump!
                // Technically JAL also needs to write OldPC+4 to rd, 
                // which requires slightly tweaking standard muxes.
            end
        endcase
    end

    // 4. IMM DECODER (Extracts Immediate format from Opcode)
    always_comb begin
        case (op)
            7'b0100011: ImmSrc = 2'b01; // sw (S-type)
            7'b1100011: ImmSrc = 2'b10; // beq (B-type)
            7'b1101111: ImmSrc = 2'b11; // jal (J-type)
            default:    ImmSrc = 2'b00; // lw, I-type ALU (I-type)
        endcase
    end

    // 5. ALU DECODER
    always_comb begin
        if (ALUOp == 2'b00) begin
            ALUControl = 4'b0000; // Add (for Memory access, PC+4, etc)
        end else if (ALUOp == 2'b01) begin
            ALUControl = 4'b0001; // Subtract (for BEQ)
        end else begin
            // R-type or I-type ALU instructions
            case (funct3)
                3'b000: begin
                    // if R-type and funct7b5 is 1, it's a subtract
                    if ({op[5], funct7b5} == 2'b11) ALUControl = 4'b0001; // sub
                    else                            ALUControl = 4'b0000; // add
                end
                3'b111: ALUControl = 4'b0010; // and
                3'b110: ALUControl = 4'b0011; // or
                3'b100: ALUControl = 4'b0100; // xor
                3'b001: ALUControl = 4'b0101; // sll
                3'b101: ALUControl = 4'b0110; // srl
                default: ALUControl = 4'b0000;
            endcase
        end
    end

endmodule