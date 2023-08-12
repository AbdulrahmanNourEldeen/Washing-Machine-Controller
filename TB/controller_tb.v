`timescale 1us/100ps
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~ DUT SIGNALS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
module controller_tb;

    reg        clk_tb;
    reg  [1:0] clk_freq_tb;
    reg        rst_n_tb;
    
    reg        coin_in_tb;
    reg        double_wash_tb;
    reg        timer_pause_tb;
    
    wire wash_done_tb;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~ TB PARAMETERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

parameter clk_period = 0.125;              //1,0.5,0.25,0.125   @1,2,4,8 Mhz respectively.

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~ INITIAL BLOCK ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
initial
   begin
      $dumpfile("controller_tb.vcd") ;       
      $dumpvars; 

      initialize(1'b1,2'b11);   // first argument : double wash ? 1 if yes ,, second argument: clock frequency 00,01,10,11
      reset();
      coin_in();
      wait(wash_done_tb);
      $display("The first washing request is done @time:", $time," seconds") ;

      #(960*clk_period);       // wait 2 min
//////////////////////////////////////////////////////////////////////////////////
      coin_in();
      double_wash_tb =1'b0;    // the second user request a single wash
      #(4350*clk_period)
      timer_pause();
      #(240*clk_period)        // 30 sec pause @ "spinning" cycle
      timer_pause();

      wait(wash_done_tb);
      $display("The second washing request is done @time:", $time," seconds") ;
//////////////////////////////////////////////////////////////////////////////////
      #(240*clk_period);       // wait 30 sec
//////////////////////////////////////////////////////////////////////////////////
      coin_in();
      double_wash_tb =1'b1;    // the third user request a double wash
      #(240*clk_period)
      timer_pause();
      #(240*clk_period)        // 60 sec pause @ "Filling_water" cycle
      timer_pause();


      wait(wash_done_tb);
      $display("The third washing request is done @time:", $time," seconds") ;
//////////////////////////////////////////////////////////////////////////////////
      $finish;
   end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~ DUT Instantiation ~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
controller DUT (
   .clk(clk_tb),
   .clk_freq(clk_freq_tb),
   .rst_n(rst_n_tb),
   .coin_in(coin_in_tb),
   .double_wash(double_wash_tb),
   .timer_pause(timer_pause_tb),

   .wash_done(wash_done_tb)
);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CLK GENERATION ~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
initial
   begin
      forever #(0.5*clk_period)  clk_tb = ~clk_tb ;

   end

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ TASKS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//_________________________ INITIALIZATION TASK ________________________
// Initializes the test signals.
task initialize;
   input double_wash;     // If high -> the user requests double wash option.
   input [1:0] clk_freq;  // The given operation frequency.

   begin
      clk_tb = 1'b0;
      rst_n_tb = 1'b0;
      timer_pause_tb = 1'b0;
      clk_freq_tb = clk_freq;
      double_wash_tb = double_wash;
   end
endtask

//____________________________ RESET TASK ______________________________
// Resets the whole system to start from a well known state.
task reset ;
 begin
  rst_n_tb = 1'b1  ;  
      #(0.5*clk_period)
  rst_n_tb = 1'b0  ;  
      #(0.5*clk_period)
  rst_n_tb = 1'b1  ;  
 end
endtask

//_________________________ TIMER PAUSE TASK __________________________
// Simulates the assertion and de-assertion of the timer_pause flag.
task timer_pause;
      if(timer_pause_tb)
         timer_pause_tb = 1'b0;
      else
         timer_pause_tb = 1'b1;
endtask

//_________________________ COIN IN TASK ______________________________
// Makes the coin_in signal high for a while to start the operation.
task coin_in;
   begin
      coin_in_tb = 1'b1;   
      #(5*clk_period)
      coin_in_tb = 1'b0;
   end
endtask

endmodule