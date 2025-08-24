#include "cs1237.h"
#include "usart.h"

/*
STM32G030

PA0：    ---->   CS1237：CLK 
PA1：   <-----> CS1237：Dout

PA5:    <-----   2040 gpio0   reset
PA4:     ----->  2040 gpio21  probe

PA2: 调试口输出，焊点或者排针

PA6:    <-----   2040 gpio2   reset adc chip
PA7:     ----->  2040 gpio20  

*/

#define HX711_SCK_Pin GPIO_PIN_0
#define HX711_Dout_Pin GPIO_PIN_1

#define GPIO_SetBits(x,y)   HAL_GPIO_WritePin(x ,y,GPIO_PIN_SET);
#define GPIO_ResetBits(x,y) HAL_GPIO_WritePin(x ,y,GPIO_PIN_RESET);

//OUT引脚输入输出 方向设置  PA3
//#define OUT_IN()  {GPIOA->CRL&=0XFFFF0FFF;GPIOA->CRL|=8<<12;}
//#define OUT_OUT() {GPIOA->CRL&=0XFFFF0FFF;GPIOA->CRL|=3<<12;}

void OUT_IN()
{
	GPIO_InitTypeDef GPIO_InitStruct = {0};
  GPIO_InitStruct.Pin = HX711_Dout_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
 
}
void OUT_OUT()
{
	GPIO_InitTypeDef GPIO_InitStruct = {0};
	GPIO_InitStruct.Pin = HX711_Dout_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
 
}


void Delay1us(void)
{
	__IO uint32_t t=0;
	
	while(t--);
}

void Delay1ms(void)
{
	int Time_Start;
	Time_Start = HAL_GetTick();

	while(HAL_GetTick() - Time_Start <=1);
}

void delay_ms(int ms)
{
	do{
		Delay1ms();
	}while(ms--);
}


void CS1237_Init_JX(void)
{	
/*	GPIO_InitTypeDef  GPIO_InitStructure;					
	
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);	
	
	// PA2 ----- CLK  设置为输出
	// PA3 ----- OUT  设置为输出
	GPIO_InitStructure.GPIO_Pin = HX711_SCK_Pin | HX711_Dout_Pin;		
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP; 		
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;		
	GPIO_Init(GPIOA, &GPIO_InitStructure);
		
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK拉高
	GPIO_SetBits(GPIOA, HX711_Dout_Pin);	// OUT拉高
	
	GPIO_InitTypeDef GPIO_InitStruct = {0};
*/
}



//配置CS1237芯片
void CS1237_Config(void)
{
	unsigned char i;
	unsigned char dat;
	unsigned int count_i=0;//溢出计时器
	
	dat = 0X2C;   //芯片地配置 内部REF 输出40HZ PGA=128 通道A 0X1C   
	OUT_OUT();
	GPIO_SetBits(GPIOA, HX711_Dout_Pin); //OUT引脚拉高
	OUT_IN();
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin);// 时钟拉低
	while(HAL_GPIO_ReadPin(GPIOA, HX711_Dout_Pin)==1) //等待CS237准备好
	{
		delay_ms(1);
		count_i++;
		if(count_i > 300)
		{
			OUT_OUT();
			GPIO_SetBits(GPIOA, HX711_Dout_Pin); // OUT引脚拉高
			GPIO_SetBits(GPIOA, HX711_SCK_Pin); // CLK引脚拉高
			return;//超时，则直接退出程序
		}
	}
	for(i=0;i<29;i++)// 1 - 29
	{
		GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
		Delay1us();
		GPIO_ResetBits(GPIOA, HX711_SCK_Pin);	// CLK=0;
		Delay1us();
	}
	OUT_OUT();
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);Delay1us();GPIO_SetBits(GPIOA, HX711_Dout_Pin);GPIO_ResetBits(GPIOA, HX711_SCK_Pin);Delay1us();//30
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);Delay1us();GPIO_SetBits(GPIOA, HX711_Dout_Pin);GPIO_ResetBits(GPIOA, HX711_SCK_Pin);Delay1us();//31
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);Delay1us();GPIO_ResetBits(GPIOA, HX711_Dout_Pin);GPIO_ResetBits(GPIOA, HX711_SCK_Pin);Delay1us();//32
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);Delay1us();GPIO_ResetBits(GPIOA, HX711_Dout_Pin);GPIO_ResetBits(GPIOA, HX711_SCK_Pin);Delay1us();//33
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);Delay1us();GPIO_SetBits(GPIOA, HX711_Dout_Pin);GPIO_ResetBits(GPIOA, HX711_SCK_Pin);Delay1us();//34
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);Delay1us();GPIO_ResetBits(GPIOA, HX711_Dout_Pin);GPIO_ResetBits(GPIOA, HX711_SCK_Pin);Delay1us();//35
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);Delay1us();GPIO_SetBits(GPIOA, HX711_Dout_Pin);GPIO_ResetBits(GPIOA, HX711_SCK_Pin);Delay1us();//36
	//37     写入了0x65
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
	Delay1us();
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin);	// CLK=0;
	Delay1us();
	
	for(i=0;i<8;i++)// 38 - 45个脉冲了，写8位数据
	{
		GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
		Delay1us();
		if(dat&0x80){
			GPIO_SetBits(GPIOA, HX711_Dout_Pin);// OUT = 1
		}
		else{
			GPIO_ResetBits(GPIOA, HX711_Dout_Pin);
		}
		dat <<= 1;
		GPIO_ResetBits(GPIOA, HX711_SCK_Pin);	// CLK=0;
		Delay1us();
	}
	GPIO_SetBits(GPIOA, HX711_Dout_Pin);// OUT = 1
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
	Delay1us();
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin);	// CLK=0;
	Delay1us();
}

// 读取芯片的配置数据
unsigned char Read_Config(void)
{
	unsigned char i;
	unsigned char dat=0;//读取到的数据
	unsigned int count_i=0;//溢出计时器
//	unsigned char k=0,j=0;//中间变量
	
	OUT_OUT();
	GPIO_SetBits(GPIOA, HX711_Dout_Pin); //OUT引脚拉高
	OUT_IN();
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin);//时钟拉低
	while(HAL_GPIO_ReadPin(GPIOA, HX711_Dout_Pin)==GPIO_PIN_SET)//等待芯片准备好数据
	{
		delay_ms(1);
		count_i++;
		if(count_i > 300)
		{
			OUT_OUT();
			GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
			GPIO_SetBits(GPIOA, HX711_Dout_Pin);	// OUT=1;
			return 1;//超时，则直接退出程序
		}
	}

	for(i=0;i<29;i++)// 产生第1到29个时钟
	{
		GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
		Delay1us();
		GPIO_ResetBits(GPIOA, HX711_SCK_Pin);	// CLK=0;
		Delay1us();
	}
	
	OUT_OUT();
	
	GPIO_SetBits(GPIOA, HX711_SCK_Pin); // CLK=1;
	Delay1us();
	GPIO_SetBits(GPIOA, HX711_Dout_Pin); 
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin); // CLK=0;
	Delay1us();// 这是第30个时钟
	
	GPIO_SetBits(GPIOA, HX711_SCK_Pin); // CLK=1;
	Delay1us();
	GPIO_ResetBits(GPIOA, HX711_Dout_Pin);
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin); // CLK=0;
	Delay1us();// 这是第31个时钟
	
	GPIO_SetBits(GPIOA, HX711_SCK_Pin); // CLK=1;
	Delay1us();
	GPIO_SetBits(GPIOA, HX711_Dout_Pin);
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin); // CLK=0;
	Delay1us();//32
	
	GPIO_SetBits(GPIOA, HX711_SCK_Pin); // CLK=1;
	Delay1us();
	GPIO_ResetBits(GPIOA, HX711_Dout_Pin);
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin); // CLK=0;
	Delay1us();//33
	
	GPIO_SetBits(GPIOA, HX711_SCK_Pin); // CLK=1;
	Delay1us();
	GPIO_SetBits(GPIOA, HX711_Dout_Pin); 
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin); // CLK=0;
	Delay1us();//34
	
	GPIO_SetBits(GPIOA, HX711_SCK_Pin); // CLK=1;
	Delay1us();
	GPIO_SetBits(GPIOA, HX711_Dout_Pin);
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin); // CLK=0;
	Delay1us();//35
	
	GPIO_SetBits(GPIOA, HX711_SCK_Pin); // CLK=1;
	Delay1us();
	GPIO_ResetBits(GPIOA, HX711_Dout_Pin);
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin); // CLK=0;
	Delay1us();//36
	
	GPIO_SetBits(GPIOA, HX711_Dout_Pin);
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
	Delay1us();
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin);	// CLK=0;
	Delay1us();//37     写入0x56 即读命令
	
	dat=0;
	OUT_IN();
	for(i=0;i<8;i++)// 第38 - 45个脉冲了，读取数据
	{
		GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
		Delay1us();
		GPIO_ResetBits(GPIOA, HX711_SCK_Pin);	// CLK=0;
		Delay1us();
		dat <<= 1;
		if(HAL_GPIO_ReadPin(GPIOA, HX711_Dout_Pin)==GPIO_PIN_SET)
			dat++;
	}
	
	//第46个脉冲
	GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
	Delay1us();
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin);	// CLK=0;
	Delay1us();
	
	OUT_OUT();
	GPIO_SetBits(GPIOA, HX711_Dout_Pin); //OUT引脚拉高
	
	return dat;
}

//读取ADC数据，返回的是一个有符号数据
int32_t Read_CS1237(void)
{
	unsigned char i;
	uint32_t dat=0;//读取到的数据
	unsigned int count_i=0;//溢出计时器
	int32_t temp;
	
	OUT_OUT();
	GPIO_SetBits(GPIOA, HX711_Dout_Pin); //OUT引脚拉高
	OUT_IN();
	GPIO_ResetBits(GPIOA, HX711_SCK_Pin);//时钟拉低
	while(HAL_GPIO_ReadPin(GPIOA, HX711_Dout_Pin)==GPIO_PIN_SET)//等待芯片准备好数据
	{
		delay_ms(1);
		count_i++;
		if(count_i > 300)
		{
			OUT_OUT();
			GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
			GPIO_SetBits(GPIOA, HX711_Dout_Pin);	// OUT=1;
			return 1;//超时，则直接退出程序
		}
	}
	
	dat=0;
	for(i=0;i<24;i++)//获取24位有效转换
	{
		GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
		Delay1us();
		dat <<= 1;
		if(HAL_GPIO_ReadPin(GPIOA, HX711_Dout_Pin)==GPIO_PIN_SET)
			dat ++;
		GPIO_ResetBits(GPIOA, HX711_SCK_Pin);	// CLK=0;
		Delay1us();
	}
	
	for(i=0;i<3;i++)//接着前面的时钟 再来3个时钟
	{
		GPIO_SetBits(GPIOA, HX711_SCK_Pin);	// CLK=1;
		Delay1us();
		GPIO_ResetBits(GPIOA, HX711_SCK_Pin);	// CLK=0;
		Delay1us();
	}
	
	OUT_OUT();
	GPIO_SetBits(GPIOA, HX711_Dout_Pin); // OUT = 1;
	
	if(dat&0x00800000)// 判断是负数 最高位24位是符号位
	{
		temp=-(((~dat)&0x007FFFFF) + 1);// 补码变源码
	}
	else
		temp=dat; // 正数的补码就是源码
	
	return temp;
}


static GPIO_InitTypeDef GPIO_InitStruct = {0};

#define CS1237_PINSCLK HX711_SCK_Pin
#define CS1237_PINDD HX711_Dout_Pin

#define CS1237_SCLK(x) HAL_GPIO_WritePin(GPIOA, CS1237_PINSCLK,x)
#define CS1237_DD(x) HAL_GPIO_WritePin(GPIOA, CS1237_PINDD,x)

#define READ_SCLK HAL_GPIO_ReadPin(GPIOA,CS1237_PINSCLK)
#define READ_DD HAL_GPIO_ReadPin(GPIOA,CS1237_PINDD)

#define CS1237_GPIO_OUT(x)  GPIO_InitStruct.Pull = GPIO_PULLUP;GPIO_InitStruct.Pin = x;GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;HAL_GPIO_Init(GPIOA, &GPIO_InitStruct)
#define CS1237_GPIO_IN(x)  GPIO_InitStruct.Pull = GPIO_PULLUP;GPIO_InitStruct.Pin = x;GPIO_InitStruct.Mode = GPIO_MODE_INPUT;GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;HAL_GPIO_Init(GPIOA, &GPIO_InitStruct)

//SCLK高100uS会关闭ADC！！！

static void cs1237_nop(void)
{
	  return;
    unsigned int i=0;
    for(i=0;i<10;i++)
__asm {
    nop
}
}

void init_cs1237(int del_time,unsigned char reg_val) // >100us
{
    
    CS1237_DD(GPIO_PIN_SET);
    CS1237_SCLK(GPIO_PIN_RESET);
    
    CS1237_GPIO_OUT(CS1237_PINDD);
    CS1237_GPIO_OUT(CS1237_PINSCLK);
    
  //  CS1237_SCLK(GPIO_PIN_SET);
   // HAL_Delay(del_time);//ms
    CS1237_SCLK(GPIO_PIN_RESET);
    HAL_Delay(del_time);//ms
	  rw_cs1237_cofig(0x65,reg_val);
	  CS1237_SCLK(GPIO_PIN_RESET);
}

unsigned long read_cs1237_data(void)
{
    unsigned short i=0;
    unsigned long tmp=0;
    

    CS1237_GPIO_IN(CS1237_PINDD);//输入数据
    CS1237_GPIO_OUT(CS1237_PINSCLK);//输出脉冲
    
  while((GPIO_PIN_SET==READ_DD));
/*    {
        i++;
        HAL_Delay(1);//ms
    }
    if(i<3200)
    {}
    else
    {
        return 0;
    }*/
    for(i=0;i<24;i++)//1-24读取数据
    {    
        tmp<<=1;
        CS1237_SCLK(GPIO_PIN_SET);
        cs1237_nop();//460ns
        CS1237_SCLK(GPIO_PIN_RESET);
        cs1237_nop();//460ns        
        if(GPIO_PIN_SET==READ_DD)
            tmp++;
    }
    for(i=0;i<3;i++)//25-27拉高数据脚
    {
        CS1237_SCLK(GPIO_PIN_SET);
        cs1237_nop();//ns
        CS1237_SCLK(GPIO_PIN_RESET);
        cs1237_nop();//ns
    }
    CS1237_GPIO_IN(CS1237_PINDD);
    tmp^=0x800000;
		tmp=(tmp / 1000)*1000;
    return tmp;
}

unsigned char rw_cs1237_cofig(unsigned char cmd,unsigned char data)
{
    unsigned char tmp=0;
    unsigned short i=0;
    unsigned char rw_flag=0;
    unsigned char cnoo = 0;
    
    if(0x65==cmd)
        rw_flag=1;
    else
        rw_flag=0;
    
    CS1237_GPIO_IN(CS1237_PINDD);
    
    while((READ_DD==1)&&(i<320))
    {
        i++;
        HAL_Delay(1);//ms
    }
    if(i<320)
    {}
    else
    {
        return 0;
    }
    for(i=1;i<25;i++)//1-24脉冲
    {
        CS1237_SCLK(GPIO_PIN_SET);
        cs1237_nop();//ns
        CS1237_SCLK(GPIO_PIN_RESET);
        cs1237_nop();//ns
    }
    for(i=25;i<27;i++)//25-26
    {
        cnoo<<=1;
        CS1237_SCLK(GPIO_PIN_SET);
        cs1237_nop();//ns        
        CS1237_SCLK(GPIO_PIN_RESET);
        cs1237_nop();//ns    
        if(1==READ_DD)
            cnoo++;
    }
    CS1237_SCLK(GPIO_PIN_SET);//27
    cs1237_nop();//ns
    CS1237_SCLK(GPIO_PIN_RESET);
    cs1237_nop();//ns
    CS1237_SCLK(GPIO_PIN_SET);//28
    cs1237_nop();//ns
    CS1237_SCLK(GPIO_PIN_RESET);
    cs1237_nop();//ns
    CS1237_SCLK(GPIO_PIN_SET);//29
    cs1237_nop();//ns
    CS1237_SCLK(GPIO_PIN_RESET);
    cs1237_nop();//ns    
  CS1237_GPIO_OUT(CS1237_PINDD);
    for(i=30;i<37;i++)//30-36
    {
        CS1237_SCLK(GPIO_PIN_SET);
        cs1237_nop();//ns
        if((cmd&0x40)==(0x40))
            CS1237_DD(1);
        else
            CS1237_DD(0);
        CS1237_SCLK(GPIO_PIN_RESET);
        cs1237_nop();//ns
        cmd<<=1;
    }
    CS1237_SCLK(GPIO_PIN_SET);//37
    cs1237_nop();//ns
    CS1237_SCLK(GPIO_PIN_RESET);
    cs1237_nop();//ns        
    if(rw_flag==1)
    {
        for(i=38;i<46;i++)//38-45
        {
            CS1237_SCLK(GPIO_PIN_SET);
            cs1237_nop();//ns
            if((data&0x80)==0x80)
                CS1237_DD(1);
            else
                CS1237_DD(0);
            CS1237_SCLK(GPIO_PIN_RESET);
            cs1237_nop();//ns    
            data<<=1;
        }
    }
    else
    {
        CS1237_GPIO_IN(CS1237_PINDD);
        for(i=38;i<46;i++)//38-45
        {
            tmp<<=1;
            CS1237_SCLK(GPIO_PIN_SET);
            cs1237_nop();//ns
            CS1237_SCLK(GPIO_PIN_RESET);
            cs1237_nop();//ns    
            if(READ_DD==1)
                tmp++;
        }
    }
    CS1237_SCLK(GPIO_PIN_SET);//46
    cs1237_nop();//ns
    CS1237_SCLK(GPIO_PIN_RESET);
    cs1237_nop();//ns    
    CS1237_GPIO_IN(CS1237_PINDD);
    return tmp;
}

