#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <asm-generic/io.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Leipo Yan");
MODULE_DESCRIPTION("Simple Linux kernel module.");
MODULE_VERSION("0.01");

#define BM_MARK_OFFSET	64

static int buf_frm_num = 215936;
static int buf_frm_size = 2048;
static int pool_start = 0x49210000;

static int __init lkm_example_init(void) {
	int i;
	unsigned long buff_ptr, ret_pa;
	unsigned int bm_mark;
	unsigned long pool_start_low = 0xffff888000000000 | pool_start;
	unsigned int count = 0;

	printk(KERN_INFO "buf_frm_num: %d buf_frm_size: %d pool_start_low: 0x%lx\n",
	       buf_frm_num, buf_frm_size, pool_start_low);

	buff_ptr = pool_start_low + BM_MARK_OFFSET;
	for (i = 0; i < buf_frm_num; i++) {
		bm_mark = *((u32 *)buff_ptr);
		if (bm_mark != 0) {
			count ++;
			printk(KERN_INFO "count %d bm_mark: 0x%x 0x%lx ret_pa: 0x%lx\n",
			       count, bm_mark, buff_ptr, ret_pa);
		}
		buff_ptr += buf_frm_size;
	}
	printk(KERN_INFO "count %d\n", count);

	return 0;
}
static void __exit lkm_example_exit(void) {
}

module_param(buf_frm_num, int, 0600);
MODULE_PARM_DESC(buf_frm_num, "Number of buffers");
module_param(buf_frm_size, int, 0600);
MODULE_PARM_DESC(buf_frm_size, "Size of buffers");
module_param(pool_start, int, 0600);
MODULE_PARM_DESC(pool_start, "Start address of pool");

module_init(lkm_example_init);
module_exit(lkm_example_exit);
