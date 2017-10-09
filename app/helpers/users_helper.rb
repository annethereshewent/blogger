module UsersHelper
	def getSelectMonths first_post_date, last_post_date
		months = (first_post_date..last_post_date).map{ |m| m.strftime('%Y%m') }.uniq.map{ |m| Date::MONTHNAMES[ Date.strptime(m, '%Y%m').mon ]}

		months
	end

	def getSelectBoxes first_post_date, last_post_date
		start_year = first_post_date.year
		end_year = last_post_date.year

		end_month = last_post_date.month;

		months = [
			'January',
			'February',
			'March',
			'April',
			'May',
			'June',
			'July',
			'August',
			'September',
			'October',
			'November',
			'December'
		]

		year_months = [];

		# year is different, start at january and end at end_month
		if start_year != end_year
			months.each_with_index do |month, index|
				if index == end_month
					break;
				end

				year_months.push(month)
			end
		else
			# the year is the same, so we can use this function to get the months in between. will be less than or equal to 12 months
			year_months = getSelectMonths(first_post_date, last_post_date)
		end
		
		render partial: 'archive_select', locals: {
			start_year: start_year,
			end_year: end_year,
			months: year_months,
			end_month: end_month-1
		}

	end
end
