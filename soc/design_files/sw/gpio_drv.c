#include "gpio_regs.h"

void gpio_set_dir(unsigned int dir){
    *GPIO_DIR = dir;
}

unsigned int gpio_read(){
    return *GPIO_DATA;
}

void gpio_write(unsigned int data){
    *GPIO_DATA = data;
}
