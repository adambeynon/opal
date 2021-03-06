class Dir
  class << self
    def chdir(dir)
      prev_cwd = `$opal.current_dir`
      `$opal.current_dir = #{dir}`
      yield
    ensure
      `$opal.current_dir = #{prev_cwd}`
    end

    def pwd
      `$opal.current_dir` || '.'
    end
    alias getwd pwd

    def home
      ENV['HOME'] || '.'
    end
  end
end
