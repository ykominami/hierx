require "hierx/version"

module Hierx
  class Error < StandardError; end

  class Hier
#    attr_reader :node_by_path , :node_by_id

    class Item
      attr_accessor :id, :content

      def initialize( node_id , content )
        @id = node_id
        @content = content
      end
    end

    def initialize( name )
      @name = name
      @count = 0
      @node_by_path = {}
      @node_by_id = {}
      @node_parent_id_by_id = {}
      @node_path_by_id = {}
      @node_children_id_by_id = {}
    end

    def get_node_by_path( path )
      @node_by_path[ path ]
    end

    def get_node_by_path_keys
      @node_by_path.keys
    end

    def get_node_by_id( id )
      @node_by_id[ id ]
    end

    def get_node_parent_id_by_id( id )
      @node_parent_id_by_id[ id ]
    end

    def get_node_children_id_by_id( id )
      @node_children_id_by_id[ id ]
    end

    def get_node_path_by_id( id )
      @node_path_by_id[ id ]
    end

    def add_with_auto_id( path , content = nil )
      node_id = @count
      @count += 1
      content = path.split('/').pop unless content
      @node_by_id[ node_id ] ||= ( @node_by_path[ path ] ||= Item.new( node_id , content ) )
      @node_path_by_id[ node_id ] ||= path
    end

    def add( node_id , path , content = nil )
      content = path.split('/').pop unless content
      @node_by_id[ node_id ] ||= ( @node_by_path[ path ] ||= Item.new( node_id , content ) )
=begin
      puts "#{path}|#{@node_by_path[ path ]}"
      puts "#{node_id}|#{@node_by_id[ node_id ]}"
=end
      @node_path_by_id[ node_id ] ||= path
    end

    def add_by_id( parent_id , content , node_id = nil )
      unless node_id
        @count += 1 if parent_id == @count
        node_id = @count
        @count += 1
      end
      @node_parent_id_by_id[ node_id ] = parent_id
      @node_children_id_by_id[parent_id] ||= []
      @node_children_id_by_id[parent_id] << node_id

      path = [@node_path_by_id[ parent_id ] , content].join('/')
      @node_path_by_id[ node_id ] = path
      @node_by_id[ node_id ] ||= (@node_by_path[ path ] ||= Item.new( node_id , content ))
    end

    def add_by_path( path )
      if path == ""
      #
      elsif path == '/'
        node_id = @count
        @count += 1
        node = Item.new( node_id , "" )
        @node_by_id[ node_id ] = node
        @node_by_path[ path ] = node
        @node_path_by_id[ node_id ] = path
      #
      else
        ary = path.split('/')
        ary.reduce(""){ |hier_str, x|
          next if x == nil

          path = [hier_str, x].join('/')
          unless @node_by_path[ path ]
            node_id = @count
            @count += 1
            node = Item.new( node_id , x )
            @node_by_id[ node_id ] = node
            @node_by_path[ path ] = node
            @node_path_by_id[ node_id ] = path
          end
          path
        }
      end
    end

    def repair
      @node_by_path.keys.sort.map{ |key|
        if key == '/'
          #
        else
          ary = key.split('/')
          ary.pop
          if ary.size == 1
            parent_path = '/'
          else
            parent_path = ary.join('/')
          end
          node = @node_by_path[ key ]
          parent_node = @node_by_path[ parent_path ]
          if node and parent_node
            @node_parent_id_by_id[ node.id ] = parent_node.id
            @node_children_id_by_id[parent_node.id] ||= []
            @node_children_id_by_id[parent_node.id] << node.id unless @node_children_id_by_id[parent_node.id].find( node.id )
          else
            p "node="
            p node
            p "parent_path="
            p parent_path
            p "parent_node="
            p parent_node
          end
        end
      }
      @node_parent_id_by_id.each { |id , parent_id|
        @node_children_id_by_id[parent_id] ||= []
        @node_children_id_by_id[parent_id] << id unless @node_children_id_by_id[parent_id].find( id )
      }
    end

    def move_by_path( node_path , dest_parent_path )
      node = @node_by_path[ node_path ]
      if node
        name = node_path.split('/').pop
        @node_by_path.delete( node_path )
        dest_path = [dest_parent_path , name].join('/')
        @node_by_path[ dest_path ] = node

        re = Regexp.new( %Q!^#{path}! )
        remove_paths = @node_by_path.keys.sort.select { |x| re.match( x ) != nil }
        remove_paths.map{ |r_path|
          dest_path = [dest_parent_path , r_path.split( path ).last].join('/')
          @node_by_path[ dest_path ] = @node_by_paht[ r_path ]
          @node_by_path.delete( r_path )
        }
      end
    end

    def rename_parent_path( node_id )
      parent_path = get_node_path_by_id( node_id )
      children = get_node_children_id_by_id( node_id )

      if children
        children.each{ | child_id |
          src_path = get_node_path_by_id( child_id )
          name = src_path.split('/').last
          dest_path = [ parent_path , name ].join('/')
          @node_path_by_id[ node_id ] = dest_path
          @node_by_path[ dest_path ] = @node_by_id[ node_id ]
          rename_parent_path( child_id )
          @node_by_path.delete( src_path )
        }
      end
    end

    def move( node_id , dest_parent_id )
      node = @node_by_id[ node_id ]
      dest_parent = @node_by_id[ dest_parent_id ]

      if node and dest_parent
        # puts "-# T"
        src_path = @node_path_by_id[ node_id ]
        @node_parent_id_by_id[ node_id ] = dest_parent_id
        name = @node_path_by_id[node_id].split('/').last
        dest_path = [ @node_path_by_id[ dest_parent_id ] , name ].join('/')
        @node_path_by_id[ node_id ] = dest_path
        @node_by_path[ dest_path ] = node

        rename_parent_path( node_id )
        @node_by_path.delete( src_path )
      else
        # puts "-# F"
      end
    end

    def get_node_by_path( path )
      node = @node_by_path[ path ]
    end

    def get_parent_node_by_path( path )
      parent_node = nil
      node = @node_by_path[ path ]
      parent_node = @node_by_path[ node.parent_path ] if node
      parent_node
    end

    def get_parent_node( node )
      parent_node = nil
      parent_node = @node_by_path[ node.parent_path ] if node
      parent_node
    end

    def get_hier_item_list
      @node_by_path.map{ |key, node|
        if node
          parent_id = @node_parent_id_by_id[ node.id ]
          if parent_id
            [ node.id , parent_id , node.content ]
          else
            [ node.id , "" , node.content ]
          end
        else
          [ "" , "" , "" ]
        end
      }
    end

    def self.init( name )
      @@hs ||= {}
      @@hs[ name ] ||= self.new( name )
    end
  end

  def init( name )
    Hier.init( name )
  end

  module_function :init
end
