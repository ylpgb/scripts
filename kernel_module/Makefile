KDIR=/local/lyan/lgm/ugw_9.x/ugw_sw/source/linux_lgm

obj-m += lkm_example.o
all:
	make -C $(KDIR) M=$(PWD) modules
clean:
	make -C $(KDIR) M=$(PWD) clean
