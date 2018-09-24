Apple2ColorDHGR.playround is a Swift playground for loading and viewing coloured Apple II Double Hires graphic files. There is a series of articles at the website www.battlestations.zone which gives a good explanation of how DHGR works on an Apple //e and Apple //c.

Because the data of a Double Hires graphic is highly interleaved, the demo must generate an array of base offsets before it can proceed to extract the information. Note: the "pixels" of the graphic are actually indices into a colour table.

The "pixels" of the graphic file is assumed to have been saved in two blobs of data. The first blob is saved with data from the Auxiliary bank of an Apple //e (or //c) from memory locations $2000-$3FFF. The second blob is in the same memory range but from the Main bank of the computer.

Each line of “pixels” consists of 80 bytes, 40 from the Auxiliary bank and 40 from the Main bank. Since bit 7 (or bit $80) of each byte is ignored so we are actually dealing with 80 x 7 bits = 560 bits per screen line. Because the “pixels” of a screen line are interleaved between Auxiliary and Main Memory, the demo extracts the data 4 bytes at a time, converts the 4x7 (= 28)  bits into seven 4-bit patterns (7x4) which are indices to a colour table. The 560 bits will be converted into a row of 140 RGB pixels.

Once we have a row of 140 RGB pixels, we proceed to convert it to a row of 560 RGB pixels; in order to create a 560x384 raw bitmap, we just double the number of rows.

When the raw bitmap is filled with all the data, return a CGImage object via a publicly-declared property. This CoreGraphics image object will be used to create an instance of NSImage which could be displayed in an NSImageView.

References:
a) http://www.battlestations.zone/2017/04/apple-ii-double-hi-res-from-ground-up.html
b) Apple IIE Technical Note #3
