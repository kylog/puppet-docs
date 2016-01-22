require 'jekyll/document'
require 'pathname'
require 'byebug'

# Let's crack this open and see what's in there.

module Jekyll
  class InvestigateGenerator < Generator
    priority :lowest

    def generate(site)
      @all_docs = {}
      puts 'about to do the thing'
      puts Time.now.to_s
      byebug

      documents = site.config['documents']
      docs_for_pages = prep_doc_data_for_pages(documents)
      site.config['document_list'] = collate_doc_data(documents)

      site.pages.each do |page|
        (baseurl, data) = doc_for_page(page.url, docs_for_pages)
        next if data.nil?
        page.data['doc'] = data
        page.data['nav'] = data['nav']
      end

      puts 'did the thing.'
      puts Time.now.to_s
      byebug
      puts 'hey'

    end

    # Takes a config documents hash, returns a slightly different documents hash with
    # some data duplicated or massaged.
    def prep_doc_data_for_pages(documents)
      documents.reduce( {} ) {|memo, (base_url, data)|
        memo[base_url] = {}
        memo[base_url]['base_url'] = base_url
        memo[base_url]['doc'] = data['doc']
        memo[base_url]['version'] = data['version']
        memo[base_url]['nav'] = (Pathname.new(base_url) + data['nav']).to_s
        memo[base_url]['external_source'] = data['external_source']
        memo[base_url]['my_versions'] = data['my_versions']

        memo
      }
    end

    # Takes a config documents hash, and returns a hierarchical hash with all the versions per document, showing
    # how to find each version in the main documents hash. Like:
    # {'pe' => {'2015.3' => '/pe/2015.3', '3.8' => '/pe/3.8'}, puppet => { ... } }
    def collate_doc_data(documents)
      documents.reduce( {} ) {|memo, (base_url, data)|
        memo[data['doc']] ||= {}
        memo[data['doc']][data['version']] = base_url

        memo
      }
    end

    # Original:
    # /pe/2015.3:
    #   doc: pe
    #   version: 2015.3
    #   nav: ./_pe_toc.html
    #   external_source:
    #     repo: git@github.com:puppetlabs/pe-docs-private.git
    #     commit: origin/pe2015.3.1
    #     subdirectory: source
    #   my_versions:
    #     puppet: 4.3
    #     facter: 3.1
    #     hiera: 3.0
    #     puppetserver: 2.2
    #     puppetdb: 3.2

    # Munged for pages:
    # /pe/2015.3:
    #   base_url: /pe/2015.3
    #   doc: pe
    #   version: 2015.3
    #   nav: /pe/2015.3/_pe_toc.html
    #   external_source:
    #     repo: git@github.com:puppetlabs/pe-docs-private.git
    #     commit: origin/pe2015.3.1
    #     subdirectory: source
    #   my_versions:
    #     puppet: 4.3
    #     facter: 3.1
    #     hiera: 3.0
    #     puppetserver: 2.2
    #     puppetdb: 3.2

    # site.config['document_list']:
    # pe:
    #   2015.3: /pe/2015.3
    #   3.8: /pe/3.8
    # puppet:
    #   4.3: /puppet/4.3/reference

    # Takes a page URL and a whole documents hash.
    # Returns a two-element array [doc_baseurl, doc_data].
    def doc_for_page(page_url, documents)
      documents.detect {|url, data| Regexp.new("^#{url}") =~ page_url}
    end
  end
end
