#include "project.h"
#include "drv_gpio.h"
#include "defines.h"

void gpio_init(void)
{
// clocks on to all ports			
  RCC_AHBPeriphClockCmd(RCC_AHBPeriph_GPIOA | RCC_AHBPeriph_GPIOB | RCC_AHBENR_GPIOFEN , ENABLE);

  GPIO_InitTypeDef  GPIO_InitStructure;


  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	
	
#ifdef ENABLE_VREG_PIN	
	GPIO_InitStructure.GPIO_Pin = VREG_PIN;
	GPIO_Init(VREG_PORT, &GPIO_InitStructure);
	GPIO_SetBits( VREG_PORT, VREG_PIN);
#endif

	
#if ( LED_NUMBER > 0 )
  GPIO_InitStructure.GPIO_Pin = LED1PIN;	
  GPIO_Init(LED1PORT, &GPIO_InitStructure); 
#if ( LED_NUMBER > 1 )	
	GPIO_InitStructure.GPIO_Pin = LED2PIN;	
  GPIO_Init(LED2PORT, &GPIO_InitStructure); 
#if ( LED_NUMBER > 2 )	
	GPIO_InitStructure.GPIO_Pin = LED3PIN;	
  GPIO_Init(LED3PORT, &GPIO_InitStructure); 
#if ( LED_NUMBER > 3 )	
	GPIO_InitStructure.GPIO_Pin = LED4PIN;	
  GPIO_Init(LED4PORT, &GPIO_InitStructure); 
#endif
#endif
#endif
#endif

#if ( AUX_LED_NUMBER > 0 )
  GPIO_InitStructure.GPIO_Pin = AUX_LED1PIN;	
  GPIO_Init(AUX_LED1PORT, &GPIO_InitStructure); 
#endif	
#if ( AUX_LED_NUMBER > 1 )
  GPIO_InitStructure.GPIO_Pin = AUX_LED2PIN;	
  GPIO_Init(AUX_LED2PORT, &GPIO_InitStructure); 
#endif	

}



// init fpv pin separately because it may use SWDAT/SWCLK don't want to enable it right away
int gpio_init_fpv(void)
{
	// only repurpose the pin after rx/tx have bound
	extern int rxmode;
	if (rxmode == RXMODE_NORMAL)
	{
		// set gpio pin as output
		GPIO_InitTypeDef GPIO_InitStructure;

		// common settings to set ports
      GPIO_InitStructure.GPIO_Pin =  FPV_PIN;
      GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
      GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
      GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
      GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
      GPIO_Init(FPV_PORT,&GPIO_InitStructure);
        
		return 1;
	}
	return 0;
}




