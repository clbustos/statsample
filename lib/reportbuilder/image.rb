# Creates an Image
# 
class ReportBuilder::Image
  @@n=1
  attr_reader :name
  def initialize(filename, options={})
    if !options.has_key? :name
      @name="Image #{@@n}"
      @@n+=1
    else
      @name=options[:name]
    end
    default_options={
      :alt=>@name,
      :chars => [ 'W', 'M', '$', '@', '#', '%', '^', 'x', '*', 'o', '=', '+',
      ':', '~', '.', ' ' ],
      :font_rows => 8,
      :font_cols => 4
    }
    @options=default_options.merge(options)
    @filename=filename
  end
  # Based on http://rubyquiz.com/quiz50.html
  def report_building_text(builder)
    require 'RMagick'


    img = Magick::Image.read(@filename).first

    # Resize too-large images. The resulting image is going to be
    # about twice the size of the input, so if the original image is too
    # large we need to make it smaller so the ASCII version won't be too
    # big. The `change_geometry' method computes new dimensions for an
    # image based on the geometry argument. The '320x320>' argument says
    # "If the image is too big to fit in a 320x320 square, compute the
    # dimensions of an image that will fit, but retain the original aspect
    # ratio. If the image is already smaller than 320x320, keep the same
    # dimensions."
    img.change_geometry('320x320>') do |cols, rows|
      img.resize!(cols, rows) if cols != img.columns || rows != img.rows
    end

    # Compute the image size in ASCII "pixels" and resize the image to have
    # those dimensions. The resulting image does not have the same aspect
    # ratio as the original, but since our "pixels" are twice as tall as
    # they are wide we'll get our proportions back (roughly) when we render.
    pr = img.rows / @options[:font_rows]
    pc = img.columns / @options[:font_cols]
    img.resize!(pc, pr)

    img = img.quantize(@options[:chars].size, Magick::GRAYColorspace)
    img = img.normalize

    out=""
    # Draw the image surrounded by a border. The `view' method is slow but
    # it makes it easy to address individual pixels. In grayscale images,
    # all three RGB channels have the same value so the red channel is as
    # good as any for choosing which character to represent the intensity of
    # this particular pixel.
    border = '+' + ('-' * pc) + '+'
    out += border+"\n"
    img.view(0, 0, pc, pr) do |view|
      pr.times do |i|
        out+= '|'
        pc.times do |j|
          out+= @options[:chars][view[i][j].red / (2**16/@options[:chars].size)]
        end
        out+= '|'+"\n"
      end
    end
    out+= border
    builder.preformatted(out)
  end
  def report_building_rtf(builder)
    raise "Not implemented on RTF::Document. Use gem install thecrisoshow-ruby-rtf for support" unless builder.rtf.respond_to? :image
    builder.rtf.image(@filename)
  end
  def report_building_html(builder)
    basedir=builder.directory+"/images"
    out=basedir+"/"+File.basename(@filename)
    if(File.exists? @filename)
      if !File.exists? out
        FileUtils.mkdir_p basedir
        FileUtils.cp @filename, out
      end
    end
    builder.html("<img src='images/#{File.basename(@filename)}' alt='#{@options[:alt]}' />")
  end
end
