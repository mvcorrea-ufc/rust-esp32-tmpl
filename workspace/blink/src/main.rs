#![no_std]
#![no_main]

use esp_backtrace as _;
use esp_println::println;
use esp_hal::{
    delay::Delay,
    gpio::{Level, Output},
    main,
};

#[main]
fn main() -> ! {
    let peripherals = esp_hal::init(esp_hal::Config::default());

    println!("esp32-c3 is booting!");

    // Set GPIO7 as an output, and set its state high initially.
    let mut led = Output::new(peripherals.GPIO8, Level::Low);

    led.set_high();

    // Initialize the Delay peripheral, and use it to toggle the LED state in a loop.
    let delay = Delay::new();

    loop {
        led.toggle();
        delay.delay_millis(500);
        println!("status: {:?}", led.output_level());
    }
}