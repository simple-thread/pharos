class ReportsController < ApplicationController
  before_filter :authenticate_user!
  after_action :verify_authorized
  before_filter :set_institution, only: [:index, :overview]

  def index
    authorize @institution
    respond_to do |format|
      format.json { render json: { report_list: 'There are no reports available yet. Check back later for a list.' } }
      format.html { }
    end
  end

  def overview
    authorize @institution
    (@institution.name == 'APTrust') ?
        @report = @institution.generate_overview_apt :
        @report = @institution.generate_overview
    respond_to do |format|
      format.json { render json: { report: @report } }
      format.html { }
      format.pdf do
        # pdf = WickedPdf.new.pdf_from_string(
        #     render_to_string('templates/pdf', layout: 'pdfs/layout_pdf'),
        #     footer: {
        #         content: render_to_string(layout: 'pdfs/layout_pdf')
        #     }
        # )
      end
    end
  end

  private

  def set_institution
    @institution = Institution.where(identifier: params[:identifier]).first
  end

end
