module controller (
   input wire        clk,
   input wire  [1:0] clk_freq,
   input wire        rst_n,
   
   input wire coin_in,
   input wire double_wash,
   input wire timer_pause,

   output reg wash_done

);


reg       start_count;              // Used to tell the counter to start counting.
reg [3:0] count_amount;             // Used to tell the counter the # of clock cycles to count.
reg       count_done;               // Used to tell the FSM that the count is done.

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ FSM  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

reg [2:0] current_state, next_state;

localparam IDLE           = 3'b000,  //FSM States (Grey encoded)
           Filling_water  = 3'b001,
           Washing        = 3'b011, 
           Rinsing        = 3'b010, 
           Spinning       = 3'b110;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ STATE TRANSITION ~~~~~~~~~~~~~~~~~~~~~~
always @(posedge clk or negedge rst_n) 
   begin
      if(!rst_n)
         current_state <= IDLE;
      else
         current_state <= next_state;
   end

// This part is used to satisfy the double wash condition.
reg   second_wash;                                   // Second_wash is a variable used to satisfy the double wash condition. 
reg   second_wash_reg;

always @(posedge clk or negedge rst_n)               // This register is used to register the second wash signal value to break any comb. loops.
   begin
      if(!rst_n)
         second_wash_reg <= 1'b0;
      else
         second_wash_reg <= second_wash;
   end
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ NEXT STATE LOGIC ~~~~~~~~~~~~~~~~~~~~~~
always @(*) 
   begin
     second_wash = 1'b0;                              // Initializing the second wash signal.
      case(current_state)
         IDLE:
            begin
               if(!coin_in)
                  next_state = IDLE;                   // Stay IDLE till the coin_in signal asserted.
               else
                  next_state = Filling_water;          // To the next state.
            end
         Filling_water:
            begin
               second_wash = double_wash;              // Raise the secon_wash signal if the user requires a double wash.

               if(count_done)                          // Is the time of this state passed ? (the counter reached the corresponding # of clock cycles?)
                  begin                                // if yes, go to the next state.
                     next_state = Washing;
                  end
               else
                  next_state = Filling_water;         // if no, then stay at this state till its period of time passes.
            end
         Washing:
            begin
               second_wash = second_wash_reg;         // Keep the value of the second_wash signal as it is.
               if(count_done)
                  begin
                     next_state = Rinsing;            // Same explaination as the previous state.
                  end
               else
                  next_state = Washing;
            end
         Rinsing:
            begin               
               if(count_done)
                  begin
                     if(second_wash_reg)                // If the user requires a double wash, go back again to the Wash and Rinse states. 
                        begin                           // and lower the second_wash signal to prevent stucking in these two states, then
                           next_state = Washing;        // complete the operation normaly.
                        end
                     else
                        next_state = Spinning;         // If the used dosnt want a double wash then go to the Spinning state and finish the
                  end                                  // operation.
               else
                  begin
                     next_state = Rinsing;
                     second_wash = second_wash_reg;    // keep the value of the secon_wash signal till the first Rinse state is done. If this
                  end                                  // line is not written, the second_wash signal will be given the initial value 0 even if
            end                                        // the double_wash signal is high.

         Spinning:
            begin
               if(count_done)                  // Last state in the operation.
                  next_state = IDLE;
               else 
                  next_state = Spinning;
            end

      default:
         next_state = IDLE;
      endcase
   end


//~~~~~~~~~~~~~~~~~~~~~~~~~ OUTPUT LOGIC ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Each state has 4 possible outputs to tell the counter the # of clocks
// to count accourding to the given (clk_freq). And when the counting is
// done, the FSM goes to the next state till the full operation complete.

always @(*) 
   begin
      case(current_state)
         IDLE:
            begin
               start_count  = 1'b0;              // Dont count anything.
               count_amount = 4'b0000;           // There is 9 unique # of clocks to count in the differnt casese of the freq. encoded in 4 bits.
               wash_done    = 1'b1;              // The washing is done and the washing machine is IDLE.
            end
         Filling_water:
            begin
               case (clk_freq)
               2'b00:
                  begin
                     start_count  = 1'b1;      // Tells the counter to start countnting.
                     count_amount = 4'b0001;   // Count the given corresponding # of clock cycles.
                     wash_done    = 1'b0;      // Wont be High till the complete operation is done.
                  end
               2'b01:
                  begin
                     start_count  = 1'b1;
                     count_amount = 4'b0110;
                     wash_done    = 1'b0;
                  end
               2'b10:
                  begin
                     start_count  = 1'b1;
                     count_amount = 4'b0101;
                     wash_done    = 1'b0;
                  end
               2'b11:
                  begin
                     start_count  = 1'b1;
                     count_amount = 4'b1101;
                     wash_done    = 1'b0;
                  end
               endcase
            end
         Washing:
            begin
               case (clk_freq)
               2'b00:
                  begin
                     start_count  = 1'b1;         // Same as previous explaination 
                     count_amount = 4'b0011;
                     wash_done    = 1'b0;
                  end
               2'b01:
                  begin
                     start_count  = 1'b1;
                     count_amount = 4'b0100;
                     wash_done    = 1'b0;
                  end
               2'b10:
                  begin
                     start_count  = 1'b1;
                     count_amount = 4'b1110;
                     wash_done    = 1'b0;
                  end  
               2'b11:
                  begin
                     start_count  = 1'b1;
                     count_amount = 4'b1100;
                     wash_done    = 1'b0;
                  end
               endcase
            end
         Rinsing:
            begin
               case (clk_freq)
               2'b00:
                  begin
                     start_count  = 1'b1;
                     count_amount = 4'b0001;
                     wash_done    = 1'b0;
                  end
               2'b01:
                  begin
                     start_count  = 1'b1;
                     count_amount = 4'b0110;
                     wash_done    = 1'b0;
                  end
               2'b10:
                  begin
                     start_count  = 1'b1;
                     count_amount = 4'b0101;
                     wash_done    = 1'b0;
                  end
               2'b11:
                  begin
                     start_count  = 1'b1;
                     count_amount = 4'b1101;
                     wash_done    = 1'b0;
                  end
               endcase
            end

         Spinning:
            begin
               case (clk_freq)
               2'b00:
                  begin
                     if(timer_pause)                // IF the timer_pause flag is asserted, tell the counter to stop counting till de-assertion
                        start_count  = 1'b0;
                     else
                        start_count  = 1'b1;

                     count_amount = 4'b0010;
                     wash_done    = 1'b0;   
                  end
               2'b01:
                  begin
                     if(timer_pause)
                        start_count  = 1'b0;
                     else
                        start_count  = 1'b1;
                     count_amount = 4'b0001;
                     wash_done    = 1'b0;  
                  end
               2'b10:
                  begin
                     if(timer_pause)
                        start_count  = 1'b0;
                     else
                        start_count  = 1'b1;
                     count_amount = 4'b0110;
                     wash_done    = 1'b0;  
                  end
               2'b11:
                  begin
                     if(timer_pause)
                        start_count  = 1'b0;
                     else
                        start_count  = 1'b1;
                     
                     count_amount = 4'b0101;
                     wash_done    = 1'b0;  
                  end
               endcase
            end
      default:
            begin
               start_count  = 1'b0;
               count_amount = 4'b0000;
               wash_done    = 1'b0;   
            end
      endcase
   end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ COUNTER ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Counts the given # of clock cycles (count_amount) and raise a flag 
// to tell the FSM that the current state is completed.  



reg [31:0] count;      // The maximun number of clocks to count is 2400M which could be stored at a 32 bit register
reg [31:0] count_comb; 

// Counter Seq. procedural block
always @(posedge clk or negedge rst_n) 
   begin
      if(!rst_n)
         count <= 32'b0;
      else if(count_done)
         count <= 32'b0;
      else
         count <= count_comb;
   end

// Counter Comb. procedural block
always @(*) 
   begin
      if(start_count) // start_count is a signal that tells the counter when to count and when to stop counting
         count_comb = count + 32'b1;
      else
         count_comb = count;
   end

// Output Comb. logic
always @(*) 
   begin
      count_done = 1'b0;
      case(count_amount)
         4'b0001: //grey encoded
            count_done = (count == 32'd120000000-1);       // 120M count
         4'b0011:                                           
            count_done = (count == 32'd300000000-1);       // 300M count
         4'b0010:
            count_done = (count == 32'd60000000-1);        // 60M count
         4'b0110:
            count_done = (count == 32'd240000000-1);       // 240M count
         4'b0100:
            count_done = (count == 32'd600000000-1);       // 600M count
         4'b0101:
            count_done = (count == 32'd480000000-1);       // 480M count
         4'b1101:
            count_done = (count == 32'd960000000-1);       // 960M count
         4'b1100:
            count_done = (count == 32'd2400000000-1);      // 2400M count
         4'b1110:
            count_done = (count == 32'd1200000000-1);      // 1200M count
         default:
            count_done = 1'b0;
      endcase
   end
   
endmodule