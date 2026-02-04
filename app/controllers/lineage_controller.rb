class LineageController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cow, only: [ :show ]

  def show
    @lineage_tree = @cow.lineage_tree(4)  # 4 generations deep
    @pedigree = @cow.pedigree_summary
    @ancestors = @cow.ancestors(3)  # 3 generations up
    @descendants = @cow.descendants(3)  # 3 generations down

    respond_to do |format|
      format.html
      format.json { render json: { lineage: @lineage_tree, pedigree: @pedigree } }
    end
  end

  def tree
    @cow = Cow.find(params[:id])
    @lineage_data = build_d3_tree_data(@cow)

    respond_to do |format|
      format.html
      format.json { render json: @lineage_data }
    end
  end

  private

  def set_cow
    @cow = Cow.find(params[:id])
  end

  def build_d3_tree_data(cow, depth = 0, max_depth = 4)
    return nil if cow.nil? || depth >= max_depth

    {
      name: cow.name,
      tag: cow.tag_number,
      breed: cow.breed,
      birth_date: cow.birth_date&.strftime("%Y-%m-%d"),
      status: cow.status,
      id: cow.id,
      children: cow.all_offspring.map { |child| build_d3_tree_data(child, depth + 1, max_depth) }.compact,
      _parents: {
        mother: cow.mother ? {
          name: cow.mother.name,
          tag: cow.mother.tag_number,
          id: cow.mother.id
        } : nil,
        sire: cow.sire ? {
          name: cow.sire.name,
          tag: cow.sire.tag_number,
          id: cow.sire.id
        } : nil
      }
    }
  end
end
