module Backend
  class BankStatementItemsController < Backend::BaseController
    def new
      safe_params = permit_params
      return head :bad_request unless @bank_statement = BankStatement.find(safe_params[:bank_statement_id])
      @bank_statement_item = BankStatementItem.new
      @bank_statement_item.attributes = safe_params
      if request.xhr?
        render partial: 'bank_statement_item_row_form', locals: { item: @bank_statement_item, bank_statement: @bank_statement }
      else
        redirect_to_back
      end
    end

    def create
      safe_params = permit_params
      return head :bad_request unless @bank_statement = BankStatement.find(safe_params[:bank_statement_id])
      letter = @bank_statement.next_letter
      @bank_statement_item = BankStatementItem.new(safe_params.merge(letter: letter))
      return head :bad_request unless @bank_statement_item.save!
      render 'bank_statements/bank_statement_item', item: @bank_statement_item
    end

    protected

    def permit_params
      params
        .reject { |_key, value| value == '0.0' || value == '' }
        .permit(:debit, :credit, :transfered_on, :letter, :name, :bank_statement_id)
    end
  end
end
