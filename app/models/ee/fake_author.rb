module EE
  class FakeAuthor
    FAKE_NAME = 'System'.freeze

    def id
      -1
    end

    def name
      FAKE_NAME
    end
  end
end
