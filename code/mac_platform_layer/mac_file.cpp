
struct read_file_result 
{
    void *Contents;
    u64 ContentsSize;
    char *Filename;
};

read_file_result 
PlatformReadEntireFile(char *Filename)
{
    read_file_result Result = {};

    NSString *Filepath = [[NSString alloc] initWithCString: Filename encoding: NSUTF8StringEncoding];
    NSData *FileData = [[NSFileManager defaultManager] contentsAtPath: Filepath];
  
    Result.Contents = (void *)FileData.bytes;
    Result.ContentsSize = (uint64)FileData.length;

    return (Result);
}
