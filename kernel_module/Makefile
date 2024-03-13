#KDIR=/local/lyan/lgm/ugw_9.x_head/ugw_sw/source/linux_lgm
#KDIR=/local/lyan/lgm/ugw_9.x/ugw_sw/source/linux_lgm
KDIR=/local/lyan/lgm/prplos/build-prplos/prplos/build_dir/target-x86_64_musl/linux-intel_x86_lgm/linux-ssh___git_mbitbucket_maxlinear_com_29418_sw_ugw_linux_git-HEAD

obj-m += lkm_example.o
all:
	make -C $(KDIR) M=$(PWD) modules
clean:
	make -C $(KDIR) M=$(PWD) clean
