
`timescale 1ns / 1ps

module tb_microblaze_led_system;

    reg sys_clock = 1'b0;
    reg [0:0] sys_reset_n = 1'b0;
    wire [3:0] led_out;

    // Clock 100 MHz: period = 10 ns
    always #5 sys_clock = ~sys_clock;

    // Entire MicroBlaze system
    Microblaze_Controller_wrapper dut (
        .sys_clock   (sys_clock),
        .sys_reset_n (sys_reset_n),
        .led_out     (led_out)
    );

    // Release system reset



initial begin
    sys_reset_n = 1'b0;

    // Hold reset for 2 us
    #2000;

    // Release reset
    sys_reset_n = 1'b1;

    $display("[%0t] System reset released", $time);
end




    // Check expected LED sequences
    initial begin
        // Wait until system starts
        wait(sys_reset_n == 1'b1);

        check_led(4'b0101, "TEST 1: LED 0101");
        check_led(4'b1010, "TEST 2: LED 1010");
        check_led(4'b0000, "TEST 3: LED OFF");
        check_led(4'b1111, "TEST 4: LED 1111");

        $display("==================================");
        $display("END-TO-END TEST PASSED");
        $display("==================================");

        $finish;
    end

    task check_led;
        input [3:0] expected;
        input [255:0] test_name;

        integer timeout_count;
        reg matched;
        begin
            matched = 1'b0;
            timeout_count = 0;

            while ((timeout_count < 1000000) &&
                   !matched) begin

                @(posedge sys_clock);
                #1;

                if (led_out === expected)
                    matched = 1'b1;

                timeout_count = timeout_count + 1;
            end

            if (matched) begin
                $display("[PASS] %s : LED = %b",
                         test_name, led_out);
            end
            else begin
                $display("[FAIL] %s : Expected %b, Got %b",
                         test_name, expected, led_out);
                $fatal(1, "LED test timeout");
            end
        end
    endtask

endmodule
