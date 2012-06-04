
#import "free_mem.h"

#import <mach/mach.h>
#import <mach/mach_host.h>

// inspired by http://stackoverflow.com/questions/5012886/knowing-available-ram-on-an-ios-device

natural_t get_free_memory(void)
{
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);        
    
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
    {
        NSLog(@"Failed to fetch vm statistics");
        return 0;
    }
    
    /* Stats in bytes */ 
    natural_t mem_free = vm_stat.free_count * pagesize;
    return mem_free;
}

