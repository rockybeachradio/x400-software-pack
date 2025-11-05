#ifndef __CS1237_H
#define __CS1237_H


//#include "stm32f10x.h"

void Delay1us(void);
void Delay1ms(void);
void delay_ms( int ms);
void CS1237_Init_JX(void);
void CS1237_Config(void);
unsigned char Read_Config(void);
int Read_CS1237(void);



#define CS1237_REF(x) (x<<6)//1off
#define CS1237_SPEED(x) (x<<4)//0\10hz 1\40hz 2\640hz 3\1280hz
#define CS1237_PGA(x)  (x<<2)//0\1 1\2 2\64 3\128
#define CS1237_CH(x)  (x<<0)//0\A 1\ 2\wd 3\nd 

void init_cs1237(int del_time,unsigned char reg_val);
unsigned long read_cs1237_data(void);
unsigned char rw_cs1237_cofig(unsigned char cmd,unsigned char data);


#endif

