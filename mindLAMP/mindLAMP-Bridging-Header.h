@import Foundation;
@import NodeMobile;

static int node_exec(NSString *script) {
	id arguments = [NSArray arrayWithObjects: @"node", @"-e", script, nil];
	int c_arguments_size = 0;
    for (id argElement in arguments) {
        c_arguments_size += strlen([argElement UTF8String]);
        c_arguments_size++;
    }
    char *args_buffer = (char *)calloc(c_arguments_size, sizeof(char));
    char *argv[[arguments count]];
    char *current_args_position = args_buffer;
    int argc = 0;
    for (id argElement in arguments) {
        const char *current_argument = [argElement UTF8String];
        strncpy(current_args_position, current_argument, strlen(current_argument));
        argv[argc] = current_args_position;
        argc++;
        current_args_position += strlen(current_args_position) + 1;
    }
    return node_start(argc, argv);
}
