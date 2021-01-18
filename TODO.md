* parse rest of the chunks - validate CRC
    a. IHDR is easy
    b. IDATA - use zlib.inflate/zlib.safeInflate
    TEST - malformed chunk
* validate required chunks are present (or absent if PLTE + grayscale)
    TEST - missing chunks/extra PLTE

{:error, msg, <raw data>}
