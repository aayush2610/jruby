#/***** BEGIN LICENSE BLOCK *****
# * Version: CPL 1.0/GPL 2.0/LGPL 2.1
# *
# * The contents of this file are subject to the Common Public
# * License Version 1.0 (the "License"); you may not use this file
# * except in compliance with the License. You may obtain a copy of
# * the License at http://www.eclipse.org/legal/cpl-v10.html
# *
# * Software distributed under the License is distributed on an "AS
# * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# * implied. See the License for the specific language governing
# * rights and limitations under the License.
# * 
# * Alternatively, the contents of this file may be used under the terms of
# * either of the GNU General Public License Version 2 or later (the "GPL"),
# * or the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
# * in which case the provisions of the GPL or the LGPL are applicable instead
# * of those above. If you wish to allow use of your version of this file only
# * under the terms of either the GPL or the LGPL, and not to allow others to
# * use your version of this file under the terms of the CPL, indicate your
# * decision by deleting the provisions above and replace them with the notice
# * and other provisions required by the GPL or the LGPL. If you do not delete
# * the provisions above, a recipient may use your version of this file under
# * the terms of any one of the CPL, the GPL or the LGPL.
# ***** END LICENSE BLOCK *****/
require "java"
require "stringio"

include_class("java.lang.String"){ |p,name| "J#{name}"}

include_class "java.io.ByteArrayOutputStream"
include_class "java.io.PipedInputStream"
include_class "java.io.PipedOutputStream"

include_class "java.util.zip.Deflater"
include_class "java.util.zip.DeflaterOutputStream"
include_class "java.util.zip.Inflater"
include_class "java.util.zip.InflaterInputStream"
include_class "java.util.zip.GZIPInputStream"
include_class "java.util.zip.GZIPOutputStream"

include_class "org.jruby.util.Adler32Ext"
include_class "org.jruby.util.CRC32Ext"
include_class "org.jruby.util.IOConverter"


#
# Implementation of the Zlib library with the help of Java classes
# Does not provide all functionality, especially in Gzip, since
# Java's implementation kindof suck.
#
module Zlib
  
    # Constants
    # Most of these are based on the constants in either java.util.zip or Zlib
    ZLIB_VERSION = "1.2.1"
    VERSION = "0.6.0"

    BINARY = 0
    ASCII = 1
    UNKNOWN = 2

    DEF_MEM_LEVEL = 8
    MAX_MEM_LEVEL = 9

    OS_UNIX = 3
    OS_UNKNOWN = 255
    OS_CODE = 11
    OS_ZSYSTEM = 8
    OS_VMCMS = 4
    OS_VMS = 2
    OS_RISCOS = 13
    OS_MACOS = 7
    OS_OS2 = 6
    OS_AMIGA = 1
    OS_QDOS = 12
    OS_WIN32 = 11
    OS_ATARI = 5
    OS_MSDOS = 0
    OS_CPM = 9
    OS_TOPS20 = 10

    DEFAULT_STRATEGY = 0
    FILTERED = 1
    HUFFMAN_ONLY = 2

    NO_FLUSH = 0
    SYNC_FLUSH = 2
    FULL_FLUSH = 3
    FINISH = 4

    NO_COMPRESSION = 0
    BEST_SPEED = 1
    DEFAULT_COMPRESSION = -1
    BEST_COMPRESSION = 9

    MAX_WBITS = 15

    #
    # Returns the string which represents the version of zlib library.
    #
    def Zlib.zlib_version
      ZLIB_VERSION
    end

    #
    # Returns the string which represents the version of this library
    #
    def Zlib.version
      VERSION
    end

    #
    # Calculates Adler-32 checksum for string, and returns updated value of adler. 
    # If string is omitted, it returns the Adler-32 initial value. 
    # If adler is omitted, it assumes that the initial value is given to adler.
    #
    def Zlib.adler32(string=nil, adler=1)
      ext = Adler32Ext.new adler
      if string
        string.each_byte {|b| ext.update(b) }
      end
      ext.getValue
    end

    #
    # Calculates CRC-32 checksum for string, and returns updated value of crc. 
    # If string is omitted, it returns the CRC-32 initial value. 
    # If crc is omitted, it assumes that the initial value is given to crc.
    #
    def Zlib.crc32(string=nil, crc=0)
      ext = CRC32Ext.new crc
      if string
        string.each_byte {|b| ext.update(b) }
      end
      ext.getValue
    end

    #
    # Returns the table for calculating CRC checksum as an array.
    #
    def Zlib.crc_table
      [0, 1996959894, 3993919788, 2567524794, 124634137, 1886057615, 3915621685, 2657392035, 249268274, 2044508324, 3772115230, 2547177864, 162941995, 
        2125561021, 3887607047, 2428444049, 498536548, 1789927666, 4089016648, 2227061214, 450548861, 1843258603, 4107580753, 2211677639, 325883990, 
        1684777152, 4251122042, 2321926636, 335633487, 1661365465, 4195302755, 2366115317, 997073096, 1281953886, 3579855332, 2724688242, 1006888145, 
        1258607687, 3524101629, 2768942443, 901097722, 1119000684, 3686517206, 2898065728, 853044451, 1172266101, 3705015759, 2882616665, 651767980, 
        1373503546, 3369554304, 3218104598, 565507253, 1454621731, 3485111705, 3099436303, 671266974, 1594198024, 3322730930, 2970347812, 795835527, 
        1483230225, 3244367275, 3060149565, 1994146192, 31158534, 2563907772, 4023717930, 1907459465, 112637215, 2680153253, 3904427059, 2013776290, 
        251722036, 2517215374, 3775830040, 2137656763, 141376813, 2439277719, 3865271297, 1802195444, 476864866, 2238001368, 4066508878, 1812370925, 
        453092731, 2181625025, 4111451223, 1706088902, 314042704, 2344532202, 4240017532, 1658658271, 366619977, 2362670323, 4224994405, 1303535960, 
        984961486, 2747007092, 3569037538, 1256170817, 1037604311, 2765210733, 3554079995, 1131014506, 879679996, 2909243462, 3663771856, 1141124467, 
        855842277, 2852801631, 3708648649, 1342533948, 654459306, 3188396048, 3373015174, 1466479909, 544179635, 3110523913, 3462522015, 1591671054, 
        702138776, 2966460450, 3352799412, 1504918807, 783551873, 3082640443, 3233442989, 3988292384, 2596254646, 62317068, 1957810842, 3939845945, 
        2647816111, 81470997, 1943803523, 3814918930, 2489596804, 225274430, 2053790376, 3826175755, 2466906013, 167816743, 2097651377, 4027552580, 
        2265490386, 503444072, 1762050814, 4150417245, 2154129355, 426522225, 1852507879, 4275313526, 2312317920, 282753626, 1742555852, 4189708143, 
        2394877945, 397917763, 1622183637, 3604390888, 2714866558, 953729732, 1340076626, 3518719985, 2797360999, 1068828381, 1219638859, 3624741850, 
        2936675148, 906185462, 1090812512, 3747672003, 2825379669, 829329135, 1181335161, 3412177804, 3160834842, 628085408, 1382605366, 3423369109, 
        3138078467, 570562233, 1426400815, 3317316542, 2998733608, 733239954, 1555261956, 3268935591, 3050360625, 752459403, 1541320221, 2607071920, 
        3965973030, 1969922972, 40735498, 2617837225, 3943577151, 1913087877, 83908371, 2512341634, 3803740692, 2075208622, 213261112, 2463272603, 
        3855990285, 2094854071, 198958881, 2262029012, 4057260610, 1759359992, 534414190, 2176718541, 4139329115, 1873836001, 414664567, 2282248934, 
        4279200368, 1711684554, 285281116, 2405801727, 4167216745, 1634467795, 376229701, 2685067896, 3608007406, 1308918612, 956543938, 2808555105, 
        3495958263, 1231636301, 1047427035, 2932959818, 3654703836, 1088359270, 936918000, 2847714899, 3736837829, 1202900863, 817233897, 3183342108, 
        3401237130, 1404277552, 615818150, 3134207493, 3453421203, 1423857449, 601450431, 3009837614, 3294710456, 1567103746, 711928724, 3020668471, 
        3272380065, 1510334235, 755167117]
    end
end

class Zlib::Error < StandardError
end

class Zlib::StreamEnd < Zlib::Error
end

class Zlib::StreamError < Zlib::Error
end

class Zlib::BufError < Zlib::Error
end

class Zlib::NeedDict < Zlib::Error
end

class Zlib::MemError < Zlib::Error
end

class Zlib::VersionError < Zlib::Error
end

class Zlib::DataError < Zlib::Error
end

#
# The abstract base class for Deflater and Inflater. 
# This implementation don't really do so much, except for provide som common
# functionality between Deflater and Inflater.
# Some of that functionality is also dubious, because of the Java
# implementation.
#
class Zlib::ZStream < Object
    def initialize
      @closed = false
      @ended = false
    end

    #
    # Not implemented.
    #
    def flush_next_out
    end
    
    def total_out
      @flater.getTotalOut
    end

    def stream_end?
      @flater.finished
    end

    #
    # Constant implementation, we can not know this.
    #
    def data_type
      Zlib::UNKNOWN
    end

    def closed?
      @closed
    end

    def ended?
      @ended
    end

    def end
      @flater.end unless @ended
      @ended = true
    end

    def reset
      @flater.reset
    end

    #
    # Constant implementation, we can not know this.
    #
    def avail_out
      0
    end

    #
    # Not implemented, no support for this.
    #
    def avail_out=(p1)
    end

    def adler
      @flater.adler
    end

    def finish
      @stream.finish
    end

    #
    # Constant implementation, we can not know this.
    #
    def avail_in
      0
    end

    #
    # Not implemented.
    #
    def flush_next_in
    end

    def total_in
      @flater.getTotalIn
    end

    def finished?
      @flater.finished
    end

    def close
      @stream.close unless @closed
      @closed = true
    end
end

#
# Zlib::Inflate is the class for decompressing compressed data.
# The implementation is patchy, due to bad underlying support
# for certain functions.
#
class Zlib::Inflate < Zlib::ZStream
    #
    # Decompresses string. Raises a Zlib::NeedDict exception if a preset dictionary is needed for decompression.
    #
    def self.inflate(string)
      zstream = Zlib::Inflate.new
      buf = zstream.inflate(string)
      zstream.finish
      zstream.close
      buf
    end

    #
    # Creates a new inflate stream for decompression. See zlib.h for details of the argument. If window_bits is nil, the default value is used.
    #
    def initialize(window_bits=nil)
      if window_bits.nil?
        window_bits = Zlib::MAX_WBITS
      end
      @flater = Inflater.new
      @write_stream = PipedOutputStream.new
      @intern_stream = PipedInputStream.new(@write_stream)
      @stream = InflaterInputStream.new(@intern_stream,@flater)
      @val = ""
    end

    #
    # Adds p1 to stream and returns self
    #
    def <<(p1)
      @write_stream.write JString.new(p1.to_s).getBytes("ISO-8859-1")
      self
    end

    #
    # No idea, no implementation
    #
    def sync_point?
      false
    end

    #
    # Sets the preset dictionary and returns string. This method is available just only after a Zlib::NeedDict exception was raised. See zlib.h for details.
    #
    def set_dictionary(p1)
      @flater.setDictionary(JString.new(p1).getBytes("ISO-8859-1")) 
      p1
    end

    #
    # Inputs string into the inflate stream and returns the output from the stream. 
    # Calling this method, both the input and the output buffer of the stream are flushed. 
    # If string is nil, this method finishes the stream, just like Zlib::ZStream#finish.
    #
    # Raises a Zlib::NeedDict exception if a preset dictionary is needed to decompress. 
    # Set the dictionary by Zlib::Inflate#set_dictionary and then call this method again with an empty string.
    #
    def inflate(string)
      if string
        @write_stream.write JString.new(string).getBytes("ISO-8859-1")
      end
      while (n = @stream.read) != -1
        @val << n
      end
      raise Zlib::NeedDict.new if @flater.needsDictionary
      val
    end

    #
    # This implementation is not correct
    #
    def sync(string)
      @write_stream.write JString.new(p1).getBytes("ISO-8859-1")
      @write_stream.flush
      false
    end
end

#
# Zlib::GzipFile is an abstract class for handling a gzip formatted compressed file. 
# The operations are defined in the subclasses, Zlib::GzipReader for reading, and Zlib::GzipWriter for writing.
#
# Zlib::GzipReader should be used by associating an IO, or IO-like, object.
#
# This implementation miss some operations, since Java does not implement much of Gzip correctly.
#
class Zlib::GzipFile
    #
    # Wraps a yield to the object and then ensures that it will be closed.
    #
    def self.wrap(obj)
      begin
        yield obj
      ensure
        obj.close if !obj.closed?
      end
      nil
    end

    #
    # Not available
    #
    def os_code
      @os_code || Zlib::OS_UNKNOWN
    end

    def closed?
      @closed || false
    end

    #
    # Not available
    #
    def orig_name
      @orig_name || nil
    end

    def to_io
      @io
    end

    #
    # Closes the GzipFile object. Unlike Zlib::GzipFile#close, this method never calls the close method of the associated IO object. 
    # Returns the associated IO object.
    #
    def finish
      @io.finish unless @finished
      @finished = true
      @io
    end

    #
    # Not available
    #
    def comment
      @comment || nil
    end

    #
    # Not available
    #
    def crc
      0
    end

    #
    # Not available
    #
    def mtime
      @mtime || nil
    end

    #
    # Not available
    #
    def sync
    end

    def close
      @io.close unless @closed
      @closed = true
    end

    #
    # Not available
    #
    def level
      Zlib::DEFAULT_COMPRESSION
    end

    #
    # Not available
    #
    def sync=(flag)
    end
end

#
# Zlib::GzipReader is the class for reading a gzipped file. GzipReader should be used an IO, or -IO-lie, object.
#
class Zlib::GzipReader < Zlib::GzipFile
    include Enumerable

    #
    # Opens file for reading, binary. 
    # If a block is provided, yields the File object to this and then unsures
    # the File is closed.
    #
    # Otherwise returns the open File object.
    #
    def self.open(filename,&block)
      gz = new(File.open(filename,"rb"))
      wrap(gz,&block)
    end

    #
    # Creates a GzipReader object associated with io. The GzipReader object reads gzipped data from io, and parses/decompresses them. 
    # At least, io must have a read method that behaves same as the read method in IO class.
    #
    # If the gzip file header is incorrect, raises an Zlib::GzipFile::Error exception.
    #
    # This particular implementation requires that io actually IS an IO-object, or child. TODO: fix this. implement wrapper of OutputStream, maybe?
    #
    def initialize(io)
      @io = GZIPInputStream.new(IOConverter.new(io).asInputStream)
      @line = 1
    end

    #
    # Not supported
    # 
    def rewind
    end
    
    # 
    # Not supported.
    #
    def lineno
      @line
    end

    #
    # Not supported.
    #
    def readline
      dst = gets
      raise EOFError.new("end of file reached") if dst.nil?
      dst
    end

    #
    # Read until len bytes have been read. If len is nil, read all remaining data.
    #
    def read(len=nil)
      val = ""
      if !len
        while n = getc
          val << n
        end
      else
        raise ArgError.new("negative length %d given",len) if len<0
        len.times do 
          if n=getc
            val << n
          else
            raise ArgError.new("to long %d given",len)
          end
        end
      end
      val
    end

    #
    # Not supported.
    #
    def lineno=(p1)
      @line = p1
    end

    #
    # Not supported
    #
    def pos
      0
    end

    # 
    # Reads a character from the stream, but raises and EOFError if the end of file has been reached.
    #
    def readchar
      val = getc
      raise EOFError.new("end of file reached") if val.nil?1
      val
    end

    #
    # Not supported.
    #
    def readlines(separator=$/)
      []
    end

    #
    # Yields for each byte until EOF.
    #
    def each_byte
      while n = getc
        yield n
      end
      nil
    end

    #
    # Returns the next 8-bit byte or nil if at end of file.
    #
    def getc
      c = @io.read
      c == -1 ? nil : c
    end

    #
    # Not supported.
    #
    def eof
      false
    end

    #
    # Not supported.
    #
    def ungetc(p1)
    end

    #
    # Not supported.
    #
    def each
    end
    
    #
    # Not supported.
    #
    def unused
    end

    #
    # Not supported.
    #
    def eof?
      eof
    end

    #
    # Not supported.
    #
    def gets(separator=$/)
    end
    
    #
    # Not supported.
    #
    def tell
    end
end

class Zlib::GzipFile::Error < Zlib::Error
end

class Zlib::GzipFile::CRCError < Zlib::GzipFile::Error
end

class Zlib::GzipFile::NoFooter < Zlib::GzipFile::Error
end

class Zlib::GzipFile::LengthError < Zlib::GzipFile::Error
end

#
# Zlib::Deflate is the class for compressing data.
# The implementation is patchy, due to bad underlying support
# for certain functions.
#
class Zlib::Deflate < Zlib::ZStream
    #
    # Compresses the given string. Valid values of level are Zlib::NO_COMPRESSION, Zlib::BEST_SPEED, 
    # Zlib::BEST_COMPRESSION, Zlib::DEFAULT_COMPRESSION, and an integer from 0 to 9.
    #
    def self.deflate(string, level=Zlib::DEFAULT_COMPRESSION)
      z = Zlib::Deflate.new(level)
      dst = z.deflate(string,Zlib::FINISH)
      z.close
      dst
    end

    # 
    # Creates a new deflate stream for compression. See zlib.h for details of each argument. 
    # If an argument is nil, the default value of that argument is used.
    #
    def initialize(level=nil,window_bits=nil, memlevel=nil,strategy=nil)
      if level.nil?
        level = Zlib::DEFAULT_COMPRESSION
      end
      if strategy.nil?
        strategy = Zlib::DEFAULT_STRATEGY
      end
      if window_bits.nil?
        window_bits = Zlib::MAX_WBITS
      end
      if memlevel.nil?
        memlevel = Zlib::DEF_MEM_LEVEL
      end
      @flater = Deflater.new(level)
      @flater.setStrategy(strategy)
      @intern_stream = ByteArrayOutputStream.new
      @stream = DeflaterOutputStream.new(@intern_stream,@flater)
    end

    #
    # String output - Writes p1 to stream. p1 will be converted to a string using to_s.
    # Returns self
    #
    def <<(p1)
      deflate(p1.to_s,Zlib::NO_FLUSH)
      self
    end

    #
    # Changes the parameters of the deflate stream. See zlib.h for details. The output from the stream by changing the params is preserved in output buffer.
    #
    def params(level,strategy)
      @flater.setLevel(level)
      @flater.setStrategy(strategy)
    end

    #
    # Sets the preset dictionary and returns string. This method is available just only after Zlib::Deflate.new or 
    # Zlib::ZStream#reset method was called. See zlib.h for details.
    # 
    def set_dictionary(string)
      @flater.setDictionary(JString.new(string).getBytes("ISO-8859-1")) 
    end

    #
    # This method is equivalent to deflate(, flush). If flush is omitted, Zlib::SYNC_FLUSH is used as flush. This 
    # method is just provided to improve the readability of your Ruby program.
    #
    def flush(flush=Zlib::SYNC_FLUSH)
      deflate('',flush)
    end

    # 
    # Inputs string into the deflate stream and returns the output from the stream. On calling this method, 
    # both the input and the output buffers of the stream are flushed. 
    # If string is nil, this method finishes the stream, just like Zlib::ZStream#finish.
    #
    # The value of flush should be either Zlib::NO_FLUSH, Zlib::SYNC_FLUSH, Zlib::FULL_FLUSH, or Zlib::FINISH. See zlib.h for details. 
    #
    def deflate(string,flush=nil)
      if string.nil?
        finish
        @intern_stream.toByteArray.to_a.pack("C*")
      else
        @stream.write(JString.new(string).getBytes("ISO-8859-1"))
        case flush
        when Zlib::FINISH
          finish
          @intern_stream.toByteArray.to_a.pack("C*")
        when Zlib::SYNC_FLUSH
          @stream.flush
        when Zlib::FULL_FLUSH
          @stream.flush
        end
      end
    end
end

#
# Zlib::GzipWriter is a class for writing gzipped files. GzipWriter should be used with an instance of IO, or IO-like, object.
#
# NOTE: Due to the limitation of Rubys finalizer, you must explicitly close GzipWriter objects by Zlib::GzipWriter#close etc. 
# Otherwise, GzipWriter will be not able to write the gzip footer and will generate a broken gzip file.
#
# The gzip-functionality in Java is slightly broken, which means that some functionality is not available here.
#
class Zlib::GzipWriter < Zlib::GzipFile
    #
    # Creates a GzipWriter object associated with io. level and strategy should be the same as the arguments of Zlib::Deflate.new. 
    # The GzipWriter object writes gzipped data to io. At least, io must respond to the write method that behaves same as write method in IO class
    #
    def initialize(io, level=nil, strategy=nil)
    p IOConverter.new(io).asOutputStream
      @io = GZIPOutputStream.new(IOConverter.new(io).asOutputStream)
    end

    #
    # Opens a file specified by filename for writing gzip compressed data, and returns a GzipWriter object associated with that file. 
    # Further details of this method are found in Zlib::GzipWriter.new and Zlib::GzipFile#wrap.
    #
    def self.open(filename,level=nil,strategy=nil,&block)
      gz = new(File.open(filename,"wb"),level,strategy)
      wrap(gz,&block)
    end

    #
    # String output - Writes p1 to stream. p1 will be converted to a string using to_s.
    # Returns self
    #
    def <<(p1)
      write p1.to_s
      self
    end


    #
    # See IO#printf
    #
    def printf(*opts)
      sio = StringIO.new
      sio.printf(opts)
      write(sio.string)
      nil
    end

    #
    # See IO#print
    #
    def print(*opts)
      sio = StringIO.new
      sio.print(opts)
      write(sio.string)
      nil
    end

    #
    # Not supported.
    #
    def pos
    end

    #
    # Not supported.
    #
    def orig_name=(p1)
      @orig_name = p1
    end

    #
    # Writes the given character on the stream.
    #
    def putc(p1)
      @io.write(p1)
    end

    #
    # Not supported.
    #
    def comment=(p1)
      @comment = p1
    end

    #
    # See IO#puts
    #
    def puts(*opts)
      sio = StringIO.new
      sio.puts(opts)
      write(sio.string)
      nil
    end

    #
    # Flushes all the internal buffers of the GzipWriter object. The meaning of flush is same as in Zlib::Deflate#deflate. 
    # Zlib::SYNC_FLUSH is used if flush is omitted. It is no use giving flush Zlib::NO_FLUSH.
    #
    def flush(flush=Zlib::SYNC_FLUSH)
      @io.flush unless flush == Zlib::NO_FLUSH
    end

    #
    # Not supported.
    #
    def mtime=(p1)
      @mtime = p1
    end

    #
    # Not supported.
    #
    def tell
    end

    #
    # Writes p1 to stream. Converts it to a string with to_s before writing.
    # 
    def write(p1)
      str = p1.to_s 
      @io.write(JString.new(str).getBytes("ISO-8859-1"))
    end
end

class Zlib::GzipFile::CRCError < Zlib::GzipFile::Error
end

class Zlib::GzipFile::Error < Zlib::Error
end

class Zlib::GzipFile::NoFooter < Zlib::GzipFile::Error
end

class Zlib::GzipFile::LengthError < Zlib::GzipFile::Error
end
