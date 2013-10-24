module Ghost
  class Reader
    def read(dir)
      ghost_string = ""

      # Concatenate all *.ghost files into one über-string
      Dir.glob(File.join(dir, "*.ghost"), File::FNM_CASEFOLD).sort.each do |filename|
        if ghost_string != ""
          ghost_string += "\n"
        end
        ghost_string += File.read filename
      end

      # Optionally concatenate timestamp manifests
      Dir.glob(File.join(dir, "*.ghost_time"), File::FNM_CASEFOLD).sort.each do |filename|
        ghost_string += "\n.ghost_time\n"
        ghost_string += File.read filename
      end

      ghost_string
    end
  end
end
