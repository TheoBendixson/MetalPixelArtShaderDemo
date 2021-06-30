
struct read_file_result 
{
    void *Contents;
    u64 ContentsSize;
    char *Filename;
};

read_file_result 
MacReadEntireFile(char *Filename)
{
    read_file_result Result = {};

    NSString *Filepath = [[NSString alloc] initWithCString: Filename encoding: NSUTF8StringEncoding];
    NSData *FileData = [[NSFileManager defaultManager] contentsAtPath: Filepath];
  
    Result.Contents = (void *)FileData.bytes;
    Result.ContentsSize = (uint64)FileData.length;

    return (Result);
}

#define MAC_MAX_FILENAME_SIZE 4096

struct mac_app_path
{
    char Filename[MAC_MAX_FILENAME_SIZE];
    char *OnePastLastAppFileNameSlash;
};

void CatStrings(size_t SourceACount, char *SourceA,
                size_t SourceBCount, char *SourceB,
                size_t DestCount, char *Dest)
{
    // TODO: Dest bounds checking!
    for(int Index = 0;
        Index < SourceACount;
        ++Index)
    {
        *Dest++ = *SourceA++;
    }

    for(int Index = 0;
        Index < SourceBCount;
        ++Index)
    {
        *Dest++ = *SourceB++;
    }

    *Dest++ = 0;
}

int
StringLength(char *String)
{
    int Count = 0;
    while(*String++)
    {
        ++Count;
    }
    return(Count);
}

void
MacBuildAppFilePath(mac_app_path *Path)
{
	u32 buffsize = sizeof(Path->Filename);
    if (_NSGetExecutablePath(Path->Filename, &buffsize) == 0) {
		for(char *Scan = Path->Filename;
			*Scan;
			++Scan)
		{
			if(*Scan == '/')
			{
				Path->OnePastLastAppFileNameSlash = Scan + 1;
			}
		}
    }
}

void
MacBuildAppPathFileName(mac_app_path *Path, char *Filename, int DestCount, char *Dest)
{
	CatStrings(Path->OnePastLastAppFileNameSlash - Path->Filename, Path->Filename,
			   StringLength(Filename), Filename,
			   DestCount, Dest);
}

read_file_result
PlatformReadEntireFile(char *Filename) 
{
    mac_app_path Path = {};
    MacBuildAppFilePath(&Path);

    char SandboxFilename[MAC_MAX_FILENAME_SIZE];
    char LocalFilename[MAC_MAX_FILENAME_SIZE];
    sprintf(LocalFilename, "Contents/Resources/%s", Filename);
    MacBuildAppPathFileName(&Path, LocalFilename,
                            sizeof(SandboxFilename), SandboxFilename);

    read_file_result Result = MacReadEntireFile(SandboxFilename);

    if (Result.ContentsSize > 0)
    {
        Result.Filename = (char *)malloc(200*sizeof(char));

        char *Dest = Result.Filename;
        char *Scan = Filename;

        while (*Scan != '\0')
        {
            *Dest++ = *Scan++;
        }

        *Dest++ = '\0';
    } else
    {
        NSLog(@"No contents loaded");
    }

    return(Result);
}

