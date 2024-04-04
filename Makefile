snd-soc-wm8960-objs := wm8960.o
snd-soc-wm8960-soundcard-objs := wm8960-soundcard.o
#snd-soc-clk-config-objs := clk-config.o


obj-m += snd-soc-wm8960.o
obj-m += snd-soc-wm8960-soundcard.o
#obj-m += snd-soc-clk-config.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
	dtc -@ -b 0 -Wno-unit_address_vs_reg -I dts -O dtb -o wm8960-soundcard.dtbo wm8960-soundcard.dts

clean:
	sudo rm -f ./minimal_clk
	sudo rm -f wm8960-soundcard.dtbo
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

install:
	sudo cp snd-soc-wm8960.ko /lib/modules/$(shell uname -r)/kernel/sound/soc/codecs/
	sudo cp snd-soc-wm8960-soundcard.ko /lib/modules/$(shell uname -r)/kernel/sound/soc/bcm/
#	sudo cp snd-soc-clk-config.ko /lib/modules/$(shell uname -r)/kernel/sound/soc/codecs/
	sudo depmod -a
