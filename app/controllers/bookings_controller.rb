class BookingsController < ApplicationController

  include CostCalculator

	def show
      @booking = Booking.find(params[:id])
      if @booking.lisp.present? and @booking.kva.present?
        @per_day = per_day_cost(@booking.lisp, @booking.kva)
        @per_hour = per_hour_cost(@booking.lisp, @booking.kva)
        if @booking.actual_days.present? and @booking.actual_hours.present?
          total = @booking.actual_days.to_i*@per_day + @booking.actual_hours.to_i*@per_hour
          total += 1500 if @booking.is_mobile?
          @management_charges = total * 0.1
          @booking.cost = total + @management_charges
          @booking.save
        end
      end
      @booking_updates = BookingUpdate.where(:booking_id => @booking.id)
  end

	def index
		if params[:status].nil?
			render json: Booking.where(:status => "completed").to_json, status: 201	
			return
		end

    bookings = nil

    if !params[:client_id].blank?
      bookings = Booking.where(:status => params[:status]).where(:client_id => params[:client_id])
    else
      bookings = Booking.where(:status => params[:status])
    end

    render json: bookings, status: 201
	end

  def approve
    booking = Booking.find(params[:id])
    from_status = booking.status
    booking.status = "client_approved"
    booking.save
    add_update_track_record(booking, from_status, "client_approved")
    render json: {}, status: 201
  end

  def cancel
    booking = Booking.find(params[:id])
    from_status = booking.status
    booking.status = "cancelled"
    booking.cost = add_cancellation_charges(booking)
    booking.save
    add_update_track_record(booking, from_status, "cancelled")
    render json: {}, status: 201
  end

	def new
	end

	def create
	  booking = Booking.new(params.require(:booking).permit(:start_date, :end_date, :gen_type, :time_in, :time_out, :lisp, :kva))

	  booking.status = "pending"
    booking.user = current_user
    booking.client = Client.find(params[:booking][:client_id])
    booking.rep = User.find(params[:booking][:rep_id])
    booking.name = "#{booking.client.name}_#{booking.user.name}"
    booking.location = booking.client.location
    booking.name = "#{booking.name}_#{booking.id}"
    
    booking.save
    
	  render json: {}, status: 201
	end

  def update
    booking = Booking.find(params[:id])

    from_status = booking.status
    booking.update!(booking_params)
    to_status = booking.status

    add_update_track_record(booking, from_status, to_status)

    if booking.status == "client_approved" and booking.vendor_id.present?
      booking.status = "accepted"
    end
    if booking.status == "accepted" and booking.slip.present?
      booking.status = "completed"
    end
    if booking_params[:actual_days].present?
      booking.cost = booking_params[:actual_days].to_i*per_day_cost(booking.lisp, booking.kva) + booking_params[:actual_hours].to_i*per_hour_cost(booking.lisp, booking.kva)
      booking.cost += 1500 if booking.is_mobile?
      booking.cost += 0.1*booking.cost
    end
    booking.operator = Operator.where(:vendor_id => booking.vendor_id).sample
    booking.save

    redirect_to '/'
  end

  private

  def add_cancellation_charges(booking)
    d = DateTime.parse(booking.start_date.to_s + "T" + booking.time_in + "+05:30")
    next_day = 1.day.from_now
    next_half_day = 0.5.day.from_now

    if next_half_day > d
      return (booking.end_date - booking.start_date + 1).to_i * per_day_cost(booking.lisp, booking.kva)
    elsif next_day > d
      return 0.5 * (booking.end_date - booking.start_date + 1).to_i * per_day_cost(booking.lisp, booking.kva)
    else
      return 0
    end
  end

  def add_update_track_record(booking, from_status, to_status)
    if from_status != to_status
      booking_update = BookingUpdate.new(:from_status => from_status, :to_status => to_status)
      booking_update.user = current_user
      booking_update.booking = booking
      booking_update.save
    end
  end

  def booking_params
    params.require(:booking).permit(:name, :email,:start_date,:end_date,:status, :user_id, :vendor_id, :slip, :actual_days, :actual_hours)
  end

end