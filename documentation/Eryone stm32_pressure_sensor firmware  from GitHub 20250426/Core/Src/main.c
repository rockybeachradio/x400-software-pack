/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2024 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "cs1237.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
IWDG_HandleTypeDef hiwdg;

UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_IWDG_Init(void);
static void MX_USART2_UART_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
uint32_t  HX711_Buffer;
uint32_t  Weight_Maopi;
uint32_t  Weight_Shiwu;
uint8_t   Flag_Error = 0;

#define TRIGER_VALUE   8000

#define SCALE      116.608


void DDelay_ms(int time)
{
//  uint8_t i;
//	for(i=time;i>0;i--);
	
	int Time_Start;
	Time_Start = HAL_GetTick();

	while(HAL_GetTick() - Time_Start <=time);


}

void Delay_us(int num)
{
  int i,j;
  for(i=0;i<num;i++)
    for(j=0;j<0x10;j++);
}

#define HX711_SCK_Pin GPIO_PIN_0
#define HX711_Dout_Pin GPIO_PIN_1
//****************************************************
//??HX711
//****************************************************
unsigned long HX711_Read(void)	//??128
{
	unsigned long data=0; 
	unsigned char i;
	Delay_us(1);
  HAL_GPIO_WritePin(GPIOA ,HX711_SCK_Pin,GPIO_PIN_RESET);
//  HAL_Delay(1);
	Delay_us(1);
	
  while(HAL_GPIO_ReadPin(GPIOA ,HX711_Dout_Pin)==GPIO_PIN_SET);
	for(i=0;i<24;i++)
	{  
	  	HAL_GPIO_WritePin(GPIOA ,HX711_SCK_Pin,GPIO_PIN_SET);
//			HAL_Delay(1);
		Delay_us(1);
			data=data<<1; 
			HAL_GPIO_WritePin(GPIOA ,HX711_SCK_Pin,GPIO_PIN_RESET); 
	Delay_us(1);
		  if(HAL_GPIO_ReadPin(GPIOA ,HX711_Dout_Pin)== GPIO_PIN_SET) 
			   data++;
//			HAL_Delay (1);		
      Delay_us(1);			
	}
  
	 HAL_GPIO_WritePin(GPIOA ,HX711_SCK_Pin,GPIO_PIN_SET);
	 data=data^0x800000;//?25????????,????	
//	 HAL_Delay(1);
	 Delay_us(1);
	 HAL_GPIO_WritePin(GPIOA ,HX711_SCK_Pin,GPIO_PIN_RESET); 

	 	
	
	return (data);
}


unsigned long data_h[10],zero_value,index_h=0;
	
unsigned long abs_bd(unsigned long a, unsigned long b){
 if (a > b)
    return a-b;
 else
 	return b-a;
}

int trigger_c(int a, int b)
{
	 if(a > (b + TRIGER_VALUE) && (a -b ) < (100000)&& a<0xffffff)
		 return 1;
	 return 0;
}
int get_index(int i){
  if (i<0)
		i = 10 + i;
	else if (i>=10)
		i=0;
	return i;
}
int push_and_triggered(unsigned long data0)
{
	 
	int ret=0;
	if (data0 > (0xffffff-10000)){ //something error on the board
		ret = 0;
		
	}
	if(index_h>=10)
		index_h = 0;
	data_h[index_h]=data0;

  if(data_h[index_h]>(zero_value + TRIGER_VALUE) // normal triggered
		&& data_h[get_index(index_h-1)]>(zero_value + TRIGER_VALUE)
	  //&& data_h[get_index(index_h-2)]>(zero_value + TRIGER_VALUE)
	  && (data_h[index_h] - zero_value) < 100000
	  && abs_bd(data_h[index_h],data_h[get_index(index_h-1)])<(TRIGER_VALUE))
	 
	{
		 if(data_h[index_h]<data_h[get_index(index_h-1)]){	 
		    ret =0;
			  data_h[index_h] = data_h[get_index(index_h-1)]=zero_value;
		 }
	   else
			  ret = 1;
	}
	if (data_h[get_index(index_h-2)]>(zero_value + TRIGER_VALUE) //unormal triggered
		     // && data_h[index_h]>data_h[get_index(index_h-1)]
	       // && data_h[get_index(index_h-1)]>data_h[get_index(index_h-2)]
	        && data_h[get_index(index_h-3)]>(zero_value + TRIGER_VALUE)
	       && data_h[get_index(index_h-1)]>(zero_value + TRIGER_VALUE)
	       && data_h[get_index(index_h)]>(zero_value + TRIGER_VALUE)
	        && data_h[get_index(index_h-4)]>(zero_value + TRIGER_VALUE))
	{
		ret =1;		 
				 
	}
		
	index_h++;
	
  return ret;
}

unsigned long get_zero_value()
{
	unsigned long data_t[4];
	static unsigned long s_sum=0;
	int i=0;
	uint8_t tmp=0;
 	
	for(i=5;i>0;i--){
		DDelay_ms(5);
		data_t[0] =  read_cs1237_data();
		DDelay_ms(5);
		data_t[1] =  read_cs1237_data();
		DDelay_ms(5);	
		data_t[2] =  read_cs1237_data();		
		DDelay_ms(5);
		data_t[3] =  read_cs1237_data();	
		////
	/*	if(data_t[0] == data_t[1] && data_t[1] == data_t[2] &&
  		   data_t[2] == data_t[3])
	  {
		    s_sum = 0;
		}
		else */
		if(abs_bd(data_t[0],data_t[1])<20000 
			&& abs_bd(data_t[1],data_t[2])<20000 
		   && abs_bd(data_t[2],data_t[3])<20000
		   && abs_bd(data_t[0],data_t[3])<20000
		  ){
		     s_sum = (data_t[0]+data_t[1]+data_t[2]+data_t[3])/4;
         break;
		 }
		else if(i<=1 && s_sum<=100){
		    s_sum = (data_t[0]+data_t[1]+data_t[2]+data_t[3])/4;
        break;
		}
	}
	for(i=0;i<10;i++){
		data_h[i] = s_sum;
	}
  //USART2_printf("get: %d \n",s_sum) ;	

	
  return s_sum;		
}

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */
   unsigned long  data_h_tmp,con_n;
	 int trigger_ret=0,i;
	 uint8_t tmp=0,old_pin=0,old_adc_rst_pin=0;
  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_IWDG_Init();
  MX_USART2_UART_Init();
  /* USER CODE BEGIN 2 */
  //MX_USART2_UART_Init();
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
	//Delay_us(6000*2);
	tmp=CS1237_REF(1)|CS1237_SPEED(2)|CS1237_PGA(3)|CS1237_CH(0);
	init_cs1237(500,tmp);
	
	rw_cs1237_cofig(0x65,tmp);
  tmp=rw_cs1237_cofig(0x56,0);
	USART2_printf("MRead:0x%x \n",tmp) ;
	if(tmp != (CS1237_REF(1)|CS1237_SPEED(2)|CS1237_PGA(3)|CS1237_CH(0)))
	{
		tmp=CS1237_REF(1)|CS1237_SPEED(2)|CS1237_PGA(3)|CS1237_CH(0);
		rw_cs1237_cofig(0x65,tmp);
		tmp=rw_cs1237_cofig(0x56,0);
		USART2_printf("SRead:0x%x \n",tmp) ;
	}
	zero_value = get_zero_value();
	con_n = 0;
	old_pin = HAL_GPIO_ReadPin(GPIOA ,GPIO_PIN_5);
	old_adc_rst_pin = HAL_GPIO_ReadPin(GPIOA ,GPIO_PIN_6);
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
		//HAL_GPIO_WritePin(GPIOA ,HX711_SCK_Pin,GPIO_PIN_SET);
		HAL_IWDG_Refresh(&hiwdg);
		DDelay_ms(1);
		//HAL_GPIO_WritePin(GPIOA ,HX711_SCK_Pin,GPIO_PIN_RESET);
    data_h_tmp =  read_cs1237_data();

		trigger_ret = push_and_triggered(data_h_tmp);
		
		//reset adc chip
		if(HAL_GPIO_ReadPin(GPIOA ,GPIO_PIN_6)== GPIO_PIN_RESET && old_adc_rst_pin == GPIO_PIN_SET)
		{
		  tmp=CS1237_REF(1)|CS1237_SPEED(2)|CS1237_PGA(3)|CS1237_CH(0);
			init_cs1237(500,tmp);
			rw_cs1237_cofig(0x65,tmp);
			zero_value=get_zero_value();
      con_n = 0;
		}
		old_adc_rst_pin = HAL_GPIO_ReadPin(GPIOA ,GPIO_PIN_6);
		// reset value 
		if(HAL_GPIO_ReadPin(GPIOA ,GPIO_PIN_5)== GPIO_PIN_RESET && old_pin == GPIO_PIN_SET) {	
			//tmp=CS1237_REF(1)|CS1237_SPEED(2)|CS1237_PGA(3)|CS1237_CH(0);
      //init_cs1237(10,tmp);			
			//USART2_printf("prepare ") ;
			zero_value=get_zero_value();
      con_n = 0;			
		}
		con_n ++;
		old_pin = HAL_GPIO_ReadPin(GPIOA ,GPIO_PIN_5);
		
	/*	if(abs_bd( data_h_tmp, zero_value) > 5000 && data_h_tmp<0xffffff &&(data_h_tmp>zero_value) &&(con_n == 4)){

				zero_value=get_zero_value();
        con_n = 0;
			
		}
		else*/ if(trigger_ret){
    //  USART2_printf("> %d %d  \n",data_h_tmp,abs_bd( data_h_tmp, zero_value)) ;
			//for(i=0;i<5;i++)
				USART2_printf("%d,",abs_bd(data_h[get_index(index_h-1-i)],zero_value)) ;
			//USART2_printf(")\n") ;
			HAL_GPIO_WritePin(GPIOA ,GPIO_PIN_4,GPIO_PIN_SET);
		}
		else{
			con_n = 800;
			USART2_printf(" %d %d \n",data_h_tmp,abs_bd( data_h_tmp, zero_value)) ;
			HAL_GPIO_WritePin(GPIOA ,GPIO_PIN_4,GPIO_PIN_RESET);
		}
		
		
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  HAL_PWREx_ControlVoltageScaling(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI|RCC_OSCILLATORTYPE_LSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSIDiv = RCC_HSI_DIV1;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.LSIState = RCC_LSI_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSI;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief IWDG Initialization Function
  * @param None
  * @retval None
  */
static void MX_IWDG_Init(void)
{

  /* USER CODE BEGIN IWDG_Init 0 */

  /* USER CODE END IWDG_Init 0 */

  /* USER CODE BEGIN IWDG_Init 1 */

  /* USER CODE END IWDG_Init 1 */
  hiwdg.Instance = IWDG;
  hiwdg.Init.Prescaler = IWDG_PRESCALER_16;
  hiwdg.Init.Window = 4095;
  hiwdg.Init.Reload = 4095;
  if (HAL_IWDG_Init(&hiwdg) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN IWDG_Init 2 */

  /* USER CODE END IWDG_Init 2 */

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  huart2.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  huart2.Init.ClockPrescaler = UART_PRESCALER_DIV1;
  huart2.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
/* USER CODE BEGIN MX_GPIO_Init_1 */
/* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOA_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_0|GPIO_PIN_4, GPIO_PIN_RESET);

  /*Configure GPIO pins : PA0 PA4 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_4|GPIO_PIN_7;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pins : PA1 PA5 */
  GPIO_InitStruct.Pin = GPIO_PIN_1|GPIO_PIN_5|GPIO_PIN_6;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

/* USER CODE BEGIN MX_GPIO_Init_2 */
/* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
