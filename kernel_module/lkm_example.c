#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Leipo Yan");
MODULE_DESCRIPTION("Simple Linux kernel module.");
MODULE_VERSION("0.01");

#include <linux/phy.h>
#define PHY_STATE_STR(_state)			\
	case PHY_##_state:			\
		return __stringify(_state);	\

static const char *phy_state_to_str(enum phy_state st)
{
	switch (st) {
	PHY_STATE_STR(DOWN)
	PHY_STATE_STR(READY)
	PHY_STATE_STR(UP)
	PHY_STATE_STR(RUNNING)
	PHY_STATE_STR(NOLINK)
	PHY_STATE_STR(CABLETEST)
	PHY_STATE_STR(HALTED)
	}

	return NULL;
}

static int __init lkm_example_init(void) {
	printk(KERN_INFO "Hello, World!\n");
	printk(KERN_INFO "%s\n", phy_state_to_str(PHY_NOLINK));
	WARN(1, "called from state\n");
	return 0;
}
static void __exit lkm_example_exit(void) {
	printk(KERN_INFO "Goodbye, World!\n");
}

module_init(lkm_example_init);
module_exit(lkm_example_exit);
