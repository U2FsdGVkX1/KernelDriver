#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("A minimal Linux driver - DRIVER_NAME");
MODULE_VERSION("1.0");

static int __init DRIVER_NAME_init(void)
{
    printk(KERN_INFO "DRIVER_NAME: Module loaded\n");
    return 0;
}

static void __exit DRIVER_NAME_exit(void)
{
    printk(KERN_INFO "DRIVER_NAME: Module unloaded\n");
}

module_init(DRIVER_NAME_init);
module_exit(DRIVER_NAME_exit);
