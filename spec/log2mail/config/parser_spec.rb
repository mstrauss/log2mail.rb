require 'spec_helper'
require 'log2mail/config/parser'
require 'parslet/rig/rspec'

module Log2mail::Config

  describe Parser do

    describe 'parse_snippets' do
      it 'should merge the results from multiple files' do
        expect( subject.parse_snippets([
          build(:defaults_snippet),
          build(:config_file_snippet),
          build(:just_comments_snippet),
          build(:config_file_snippet)
        ]).tree ).to eq({
          :defaults=>{:mailtos=>{"global_default_recipient@example.org"=>{}}},
          :files=>{
            "file1"=>{:patterns=>{"for file1"=>{:mailtos=>{"for pattern for file1"=>{}}}}},
            "file2"=>{:patterns=>{"for file2"=>{:mailtos=>{"for pattern for file2"=>{}}}}},
          }
        })
      end

      it 'should correctly merge configurations for THE SAME file', :focus do
        expect( subject.parse_snippets([
          ConfigFileSnippet.new(<<-TEXT, 'configfile1'),
file = /file/path
  pattern = pattern1
    mailto = for pattern1
          TEXT
          ConfigFileSnippet.new(<<-TEXT, 'configfile2'),
file = /file/path
  pattern = pattern2
    mailto = for pattern2
          TEXT
          build(:config_file_snippet)
        ]).tree ).to eq({
          :files=>{
            "/file/path"=>{:patterns=>{
              "pattern1"=>{:mailtos=>{"for pattern1"=>{}}},
              "pattern2"=>{:mailtos=>{"for pattern2"=>{}}} }},
            "file1"=>{:patterns=>{"for file1"=>{:mailtos=>{"for pattern for file1"=>{}}}}},
          }
        })
      end

      it 'should correctly merge configurations for THE SAME file' do
        expect( subject.parse_snippets([
          ConfigFileSnippet.new(<<-TEXT, 'configfile'),
file = /file/path
  pattern = pattern1
    mailto = for pattern1
# file = /file/path
  pattern = pattern2
    mailto = for pattern2
          TEXT
          build(:config_file_snippet)
        ]).tree ).to eq({
          :files=>{
            "/file/path"=>{:patterns=>{
              "pattern1"=>{:mailtos=>{"for pattern1"=>{}}},
              "pattern2"=>{:mailtos=>{"for pattern2"=>{}}} }},
            "file1"=>{:patterns=>{"for file1"=>{:mailtos=>{"for pattern for file1"=>{}}}}},
          }
        })
      end

    end

    describe 'invalid configurations should fail' do
      it{ expect{ subject.parse_and_transform("defaults") }.to raise_error(Parslet::ParseFailed) }
      it{ expect{ subject.parse_and_transform("file\n") }.to raise_error(Parslet::ParseFailed)}
      it{ expect{ subject.parse_and_transform("invalid_attribute = some value\n") }.to raise_error(Parslet::ParseFailed)}
      it{ expect{ subject.parse_and_transform("defaults\n  invalid_attribute = some value\n") }.to raise_error(Parslet::ParseFailed)}
      it{ expect{ subject.parse_and_transform("pattern = string pattern\n") }.to raise_error(Parslet::ParseFailed)}
      it{ expect{ subject.parse_and_transform("pattern = /regexp pattern/\n") }.to raise_error(Parslet::ParseFailed)}
    end

    describe '#tree should build hash trees' do
      it{ expect( subject.parse_and_transform("").tree ).to eq({}) }
      it{ expect( subject.parse_and_transform("defaults\n").tree ).to eq(defaults: {}) }
      it{ expect( subject.parse_and_transform("file = /some/where/on/the/path\n").tree ).to eq(files:{'/some/where/on/the/path'=>{}}) }
      it{ expect( subject.parse_and_transform("file = /some/where/on/the/path\npattern = test pattern\n").tree ).to eq \
        files:{'/some/where/on/the/path' => {patterns:{'test pattern'=>{}}}} }
      it{ expect( subject.parse_and_transform("defaults\n  fromaddr = some value\n").tree ).to eq(defaults:{fromaddr: 'some value'}) }
      it{ expect( subject.parse_and_transform("defaults\n  pattern = string pattern\n").tree ).to eq(defaults:{patterns:{'string pattern'=>{}}}) }
      it{ expect( subject.parse_and_transform("defaults\n  pattern = string pattern\n  pattern = another pattern\n").tree ).to eq(defaults:{patterns:{'string pattern'=>{}, 'another pattern'=>{}}}) }
      it{ expect( subject.parse_and_transform("defaults\n  pattern = \"quoted string pattern \" # with comment\n").tree ).to eq(defaults:{patterns:{'quoted string pattern '=>{}}}) }
      it{ expect( subject.parse_and_transform("defaults\n  pattern = \"multiline\n\nquoted string pattern\"\n").tree ).to eq(defaults:{patterns:{"multiline\n\nquoted string pattern"=>{}}}) }
      it{ expect( subject.parse_and_transform(['defaults', "\n", 'pattern = "escaped \\"quoted\\" string pattern"', "\n"].join('') ).tree ).to eq \
        defaults:{patterns:{'escaped "quoted" string pattern'=>{}}} }
      it{ expect( subject.parse_and_transform("defaults\n  pattern = /regexp pattern/\n").tree ).to eq(defaults:{patterns:{'/regexp pattern/'=>{}}}) }
      it{ expect( subject.parse_and_transform("defaults\nfile = bla\n").tree ).to eq(defaults: {}, files:{'bla'=>{}})}

      it{ expect( subject.parse_and_transform("file = file one\npattern = pattern for file one\npattern = second pattern for file one\nfile = file two\npattern = pattern for file two\n").tree ).to eq ({
        files:{
          'file one' => { patterns:{'pattern for file one'=>{}, 'second pattern for file one'=>{}} },
          'file two' => { patterns:{'pattern for file two'=>{}} },
        }
      })}

      it{ expect( subject.parse_and_transform(build(:valid_raw_config)).tree ).to eq({
        defaults:{
          sendtime: 20,
          resendtime: 50,
          maxlines: 7,
          template: '/tmp/mail_template',
          fromaddr: 'log2mail',
          sendmail: '/usr/sbin/sendmail -oi -t',
          mailtos: {'global_default_recipient@example.org'=>{}}},
        files:{
          'test.log' => {
            patterns:{
              '/any/'=>{},
              'string match'=>{ mailtos:{'special@recipient'=>{ maxlines: 99} } }
            }
          }
        }
      }) }

      it{ expect( subject.parse_and_transform(build(:valid_raw_config_without_defaults)).tree ).to \
        eq( files:{'test.log'=>{ patterns:{'/any/'=>{}, 'string match'=>{mailtos:{'special@recipient'=>{}}}} }} )}
    end

    it{ expect( subject.parse_and_transform("") ).to eq(Config.new) }

    it{ expect( subject.parse_and_transform("#\n") ).to eq(Config.new) }

    it{ expect{ subject.parse_and_transform("file = a file\n  pattern = a pattern\n  \# a comment\n") }.not_to raise_error }
    it{ expect{ subject.parse_and_transform("defaults\n  pattern = a pattern\n  \# a comment\n") }.not_to raise_error }

    it 'disallows file -> mailto' do
      expect{ subject.parse_and_transform("file = a file\nmailto = a recipient\n")}.to \
        raise_error Parslet::ParseFailed, /Extra input after last repetition at line 2 char 1/
    end

    it 'allows file -> pattern' do
      expect{ subject.parse_and_transform("file = a file\npattern = a pattern\n")}.not_to raise_error
    end

    it 'allows file -> pattern -> mailto' do
      expect{ subject.parse_and_transform("file = a file\npattern = a pattern\nmailto = a mailto\n")}.not_to raise_error
    end

    it 'allows file -> #comment -> pattern -> mailto' do
      expect{ subject.parse_and_transform("file = a file\n\# a comment\npattern = a pattern\nmailto = a mailto\n")}.not_to raise_error
    end

    it 'allows file -> pattern -> #comment -> mailto' do
      expect{ subject.parse_and_transform("file = a file\npattern = a pattern\n\# a comment\nmailto = a mailto\n")}.not_to raise_error
    end

    it 'allows defaults -> mailto' do
      expect{ subject.parse_and_transform("defaults\nmailto = a global mailto\n")}.not_to raise_error
    end

    it 'allows defaults -> mailto' do
      expect{ subject.parse_and_transform("defaults\nmailto = a global mailto\n")}.not_to raise_error
    end

    it 'disallows mailto' do
      expect{ subject.parse_and_transform("mailto = a recipient\n")}.to \
        raise_error Parslet::ParseFailed, /Extra input after last repetition at line 1 char 1/
    end

    it 'allows defaults -> #command -> mailto' do
      expect{ subject.parse_and_transform("defaults\n\# a comment\nmailto = a global mailto\n")}.not_to raise_error
    end


    describe 'defaults -> mailto -> attribute' do
      it{ expect{ subject.parse_and_transform("defaults\nmailto = a global mailto\nsendtime = a mailto setting\n")}.not_to raise_error }
      it 'assigns attribute to the global mailto' do
        expect( subject.parse_and_transform("defaults\nmailto = a global mailto\nsendtime = a mailto setting\n").tree).to eq(
          {:defaults=>{:mailtos=>{"a global mailto"=>{:sendtime=>"a mailto setting"}} }})
      end
    end


    describe 'defaults -> pattern -> attribute' do
      it{ expect{ subject.parse_and_transform("defaults\npattern = a global pattern\nsendtime = a pattern setting\n")}.not_to raise_error }
      it 'assigns attribute to the global pattern' do
        expect( subject.parse_and_transform("defaults\npattern = a global pattern\nsendtime = a pattern setting\n").tree).to eq(
          {:defaults=>{:patterns=>{"a global pattern"=>{:sendtime=>"a pattern setting"}} }})
      end
    end

    it{ expect( subject.parse_and_transform("\n") ).to eq(Config.new) }

    it{ expect( subject.parse_and_transform("defaults\n") ).to eq(Config.new([Section.new(:defaults)])) }

    it{ expect( subject.parse_and_transform(" defaults \n") ).to eq(Config.new([Section.new(:defaults)])) }

    it{ expect( subject.parse_and_transform("\# comment\n") ).to eq(Config.new) }

    it{ expect( subject.parse_and_transform("defaults \# with comment\n") ).to eq(Config.new([Section.new(:defaults)])) }

    it{ expect( subject.parse_and_transform("file = /some/where/on/the/path\n") ).to eq \
      Config.new [ Section.new(:file, '/some/where/on/the/path') ] }

    it{ expect( subject.parse_and_transform("file = /some/where/on/the/path\npattern = test pattern\n") ).to eq \
      Config.new [ Section.new(:file, '/some/where/on/the/path', [Section.new(:pattern,'test pattern')]) ] }

    it{ expect( subject.parse_and_transform("defaults\n  fromaddr = some value\n") ).to eq \
      Config.new [ Section.new(:defaults, nil, [Attribute.new(:fromaddr,'some value')]) ] }

    it 'should collapse multiple default sections' do
      expect( subject.parse_and_transform("defaults\n  mailto=recipient@anywhere.com\ndefaults\n") ).to eq \
        Config.new [ Section.new(:defaults, nil, [Section.new(:mailto,'recipient@anywhere.com')]) ]
    end

    it{ expect( subject.parse_and_transform("defaults\nfile = bla\n") ).to eq \
      Config.new [ Section.new(:defaults,nil), Section.new(:file, 'bla') ] }

  end

  describe Transform do
    it 'transforms quoted strings' do
      expect( subject.apply( {:quoted_string=>"multiline\n\nquoted string pattern"} ) ).to eq("multiline\n\nquoted string pattern")
    end

    it 'transforms unquoted strings' do
      expect( subject.apply( {:unquoted_string=>"a string with spaces at the end  "} ) ).to eq('a string with spaces at the end')
    end

    it 'transforms integers' do
      expect( subject.apply( {:integer=>"123"} ) ).to eq(123)
    end

    it 'transforms attribute names' do
      INT_OPTIONS.each do |opt|
        rnd_int = rand(2**31)
        expect( subject.apply( {:attribute_name=>opt, :attribute_value=>{:integer=>rnd_int} } ) ).to eq(Attribute.new(opt, rnd_int))
      end
      STR_OPTIONS.each do |opt|
        rnd_string = rand(36**10).to_s(36)
        expect( subject.apply( {:attribute_name=>opt, :attribute_value=>rnd_string } ) ).to eq(Attribute.new(opt, rnd_string))
      end
      PATH_OPTIONS.each do |opt|
        expect( subject.apply( {:attribute_name=>opt, :attribute_value=>'/a/path/string' } ) ).to eq(Attribute.new(opt, '/a/path/string'))
      end
    end

    it 'transforms section names' do
      expect( subject.apply( {:section_name=>'file', :section_value=>'/a/file/path' } ) ).to eq(Section.new('file', '/a/file/path'))
      expect( subject.apply( {:section_name=>'defaults' } ) ).to eq(Section.new('defaults'))
    end

    it 'transforms single file section without attributes' do
      expect( subject.apply({
        section:[
          {section_name: 'file', section_value: '/file/path'},
        ]
      } ) ).to eq(
        Section.new(:file, '/file/path' )
      )
    end

    it 'transforms single file section with attributes' do
      expect( subject.apply({
        section:[
          {section_name: 'file', section_value: '/file/path'},
          {attribute_name: 'sendtime', attribute_value: '123'},
          {attribute_name: 'fromaddr', attribute_value: 'sender@address'},
        ]
      } ) ).to eq(
        Section.new(:file, '/file/path', [Attribute.new(:sendtime,'123'), Attribute.new(:fromaddr,'sender@address')] )
      )
    end

    it 'transforms simple (non-array) sections' do
      expect( subject.apply(
        {:section=>
          {:section_name=>"pattern",
           :section_value=>{:unquoted_string=>"pattern for file one"}}}
      ) ).to eq(
        Section.new(:pattern, 'pattern for file one' )
      )
    end

    it 'transforms single file section with subsections' do
      transform = subject.apply(
         {:section=>
           [{:section_name=>"file",
             :section_value=>{:unquoted_string=>"file one"}},
            {:section=>
              {:section_name=>"pattern",
               :section_value=>{:unquoted_string=>"pattern for file one"}}},
            {:section=>
              {:section_name=>"pattern",
               :section_value=>
                {:unquoted_string=>"second pattern for file one"}}}]},
      )
      expect(transform).to eq(
        Section.new(:file, 'file one', [
          Section.new(:pattern, 'pattern for file one'),
          Section.new(:pattern, 'second pattern for file one')] )
      )
    end

    ### undecided case
    # it 'transforms multiple file sections' do
    #   expect( subject.apply({
    #     section:[
    #       {section_name: 'file', section_value: '/file/path1'},
    #       {section_name: 'file', section_value: '/file/path2'},
    #     ]
    #   } ) ).to eq({
    #     files: ['/file/path1', '/file/path2']
    #   })
    # end
    #

    it 'transforms single defaults section' do
      expect( subject.apply({
        section:[
          {section_name: 'defaults'},
        ]
      } ) ).to eq( Section.new(:defaults) )
    end

    it 'transforms defaults section with attributes' do
      expect( subject.apply({
        section:[
          {section_name: 'defaults'},
          {attribute_name: 'sendtime', attribute_value: '123'},
          {attribute_name: 'fromaddr', attribute_value: 'sender@address'},
        ]
      } ) ).to eq(
        Section.new(:defaults, nil, [Attribute.new(:sendtime,'123'), Attribute.new(:fromaddr, 'sender@address')])
      )
    end


    it 'transforms trivial config' do
      expect( subject.apply({
        config:[1,2,3]
      } ) ).to eq(
        Log2mail::Config::Config.new([1,2,3])
      )
    end

    it 'transforms defaults only config' do
      expect( subject.apply({
        config:[
          section:[
            {section_name: 'defaults'},
            {attribute_name: 'sendtime', attribute_value: '123'},
            {attribute_name: 'fromaddr', attribute_value: 'sender@address'},
          ]
        ]
      } ) ).to eq(Config.new([
        Section.new(:defaults, nil, [Attribute.new(:sendtime,'123'), Attribute.new(:fromaddr, 'sender@address')])
      ]))
    end

    it 'transforms file only config' do
      expect( subject.apply({
        config:[
          section:[
            {section_name: 'file', section_value: '/file/path1'},
            {attribute_name: 'sendtime', attribute_value: '888'},
            {attribute_name: 'fromaddr', attribute_value: 'other@address'},
          ],
        ]
      } ) ).to eq(Config.new([
        Section.new(:file, '/file/path1', [Attribute.new(:sendtime,'888'), Attribute.new(:fromaddr,'other@address')]),
      ]))
    end

    it 'transforms combined config' do
      expect( subject.apply(
      {:config=>
        [{:section=>
           [{:section_name=>"defaults"},
            {:attribute_name=>"sendtime",
             :attribute_value=>{:integer=>"20"}},
            {:attribute_name=>"resendtime",
             :attribute_value=>{:integer=>"50"}},
            {:attribute_name=>"maxlines", :attribute_value=>{:integer=>"7"}},
            {:attribute_name=>"template",
             :attribute_value=>{:unquoted_string=>"/tmp/mail_template"}},
            {:attribute_name=>"fromaddr",
             :attribute_value=>{:unquoted_string=>"log2mail"}},
            {:attribute_name=>"sendmail",
             :attribute_value=>{:unquoted_string=>"/usr/sbin/sendmail -oi -t"}},
            {:attribute_name=>"mailto",
             :attribute_value=>
              {:unquoted_string=>"global_default_recipient@example.org  "}}]},
         {:section=>
           [{:section_name=>"file",
             :section_value=>{:unquoted_string=>"test.log"}},
            {:section=>
              {:section_name=>"pattern",
               :section_value=>{:unquoted_string=>"/any/"}}},
            {:section=>
              [{:section_name=>"pattern",
                :section_value=>{:unquoted_string=>"string match"}},
               {:section=>
                 [{:section_name=>"mailto",
                   :section_value=>{:unquoted_string=>"special@recipient"}},
                  {:attribute_name=>"maxlines",
                   :attribute_value=>{:integer=>"99"}}]}]}]}]}
      )).to eq(
        Log2mail::Config::Config.new([
          Section.new(:defaults, nil, [
            Attribute.new(:sendtime,20),
            Attribute.new(:resendtime, 50),
            Attribute.new(:maxlines, 7),
            Attribute.new(:template, '/tmp/mail_template'),
            Attribute.new(:fromaddr, 'log2mail'),
            Attribute.new(:sendmail, '/usr/sbin/sendmail -oi -t'),
            Attribute.new(:mailto, 'global_default_recipient@example.org')]),
          Section.new(:file, 'test.log', [
            Section.new(:pattern,'/any/'),
            Section.new(:pattern, 'string match', [Section.new(:mailto, 'special@recipient', [Attribute.new(:maxlines, 99)])])])
        ])
      )
    end

    it 'transforms combined config' do
      expect( subject.apply({
        config:[
          {section:[
            {section_name: 'defaults'},
            {attribute_name: 'sendtime', attribute_value: '123'},
            {attribute_name: 'fromaddr', attribute_value: 'sender@address'},
          ]},
          {section:[
            {section_name: 'file', section_value: '/file/path1'},
            {attribute_name: 'sendtime', attribute_value: '888'},
            {attribute_name: 'fromaddr', attribute_value: 'other@address'},
          ]},
          {section:[
            {section_name: 'file', section_value: '/file/path2'},
          ]}
        ]
      } ) ).to eq(
        Log2mail::Config::Config.new([
          Section.new(:defaults, nil, [Attribute.new(:sendtime,'123'), Attribute.new(:fromaddr, 'sender@address')]),
          Section.new(:file, '/file/path1', [Attribute.new(:sendtime,'888'), Attribute.new(:fromaddr,'other@address')]),
          Section.new(:file, '/file/path2' )
        ])
      )
    end

    it 'transforms combined SAME FILE config' do
      expect( subject.apply({
        config:[
          {section:[
            {section_name: 'file', section_value: '/the/file/path'},
            {attribute_name: 'sendtime', attribute_value: '888'},
            {attribute_name: 'fromaddr', attribute_value: 'other@address'},
          ]},
          {section:[
            {section_name: 'file', section_value: '/the/file/path'},
            {attribute_name: 'sendtime', attribute_value: '111'},
          ]},
        ]
      } ) ).to eq( #{:files => {"/the/file/path"=>{:sendtime=>"111", :fromaddr=>'other@address'}}})
      Config.new([Section.new(:file, '/the/file/path', [Attribute.new(:sendtime,'111'), Attribute.new(:fromaddr,'other@address')]) ]))
    end

  end

end
