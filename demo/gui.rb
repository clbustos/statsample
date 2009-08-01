#!/usr/bin/ruby

require 'gtk2'


button = Gtk::Button.new("Hello World")
button.signal_connect("clicked") {
  puts "Hello World"
}

dialog = Gtk::AboutDialog.new


pb=Gdk::Pixbuf.new(Gdk::Pixbuf::ColorSpace::RGB, false, 8, 300, 300)
window = Gtk::Window.new  
da=Gtk::DrawingArea.new
da.set_size_request(300,300)



box= Gtk::VBox.new()
box.pack_start(button)
box.pack_start(da)

                          
window.signal_connect("delete_event") {
  puts "delete event occurred"
  #true
  false
}


window.signal_connect("destroy") {
  puts "destroy event occurred"
  Gtk.main_quit
}

window.border_width = 10
window.add(box)
window.show_all
da.signal_connect("expose_event") do
blanco=Gdk::GC.new(da.window)  
blanco.rgb_bg_color=Gdk::Color.new(255,255,255)

back=Gdk::GC.new(da.window)
  back.rgb_bg_color=Gdk::Color.new(255,255,255)
  back.rgb_fg_color=Gdk::Color.new(255,0,0)
  
  back.set_line_attributes(3,Gdk::GC::LINE_DOUBLE_DASH, Gdk::GC::CAP_BUTT, Gdk::GC::JOIN_ROUND)

    da.window.draw_rectangle(blanco, true,0, 0, 300, 300)
    da.window.draw_line(back,10,10,40,40) 
end


Gtk.main