# frozen_string_literal: true

module Jekyll
  module Infrastructure
    # Subclass of Jekyll::StaticFile that writes generated content
    # instead of copying a source file. Used for Markdown output files
    # that must bypass Jekyll's Markdown-to-HTML conversion pipeline.
    class GeneratedStaticFile < Jekyll::StaticFile
      attr_reader :generated_dir, :generated_name

      def initialize(site, dir, name, content)
        @generated_content = content
        @generated_dir = dir
        @generated_name = name
        super(site, site.source, dir, name)
      end

      def destination(dest)
        File.join(dest, @generated_dir, @generated_name)
      end

      def write(dest) # rubocop:disable Naming/PredicateMethod
        dest_path = destination(dest)
        FileUtils.mkdir_p(File.dirname(dest_path))
        File.write(dest_path, @generated_content)
        true
      end
    end
  end
end
