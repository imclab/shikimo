require "carrierwave-daltonize/version"

require 'vips'
require 'carrierwave/vips'

module Carrierwave
  module Daltonize

    include Carrierwave::Vips

    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def deuteranope
        process :deuteranope
      end
    end

    def deuteranope
      binding.pry
      manipulate! do |image|
        begin
            # import to CIELAB with lcms
            # if there's no profile there, we'll fall back to the thing below
            cielab = image.icc_import_embedded(:relative)
        rescue VIPS::Error
            # nope .. use the built-in converter instead
            cielab = image.srgb_to_xyz().xyz_to_lab()
        end

        # turn to XYZ, a linear light space
        xyz = cielab.lab_to_xyz()

        # convert rgb to lms
        lms = xyz.recomb([[17.8824, 43.5161, 4.11935],
                          [3.45565, 27.1554, 3.86714],
                          [0.0299566, 0.184309, 1.46709]])                    

        # through the Deuteranope matrix
        deut = lms.recomb([[1, 0, 0],
                            [0.494207, 0, 1.24827],
                            [0, 0, 1]])

        # back to xyz (this is the inverse of the lms matrix above)
        xyz = deut.recomb([[0.0809444479, -0.130504409, 0.116721066],
                           [-0.0102485335, 0.0540193266, -0.113614708],
                           [-0.000365296938, -0.00412161469, 0.693511405]])

        # .. and export to sRGB for saving
        rgb = xyz.xyz_to_srgb()
        image = rgb
      end
    end
  end
end
