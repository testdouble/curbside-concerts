defmodule CurbsideConcertsWeb.RequestView do
  use CurbsideConcertsWeb, :view

  alias CurbsideConcerts.Requests
  alias CurbsideConcerts.Requests.Request
  alias CurbsideConcerts.Musicians.Genre
  alias CurbsideConcerts.Musicians.Musician
  alias CurbsideConcerts.Musicians.Session
  alias CurbsideConcertsWeb.Helpers.RequestAddress
  alias CurbsideConcertsWeb.Helpers.TimeUtil
  alias CurbsideConcertsWeb.LayoutView
  alias CurbsideConcertsWeb.TrackerCypher

  def required_star do
    ~E|<span class="required">*</span>|
  end

  @pending_state Requests.pending_state()
  @accepted_state Requests.accepted_state()
  @enroute_state Requests.enroute_state()
  @arrived_state Requests.arrived_state()
  @completed_state Requests.completed_state()
  @canceled_state Requests.canceled_state()
  @offmission_state Requests.offmission_state()

  @doc """
  Given either a Request or a string representating a request
  state, returns the message text associated with that state.

  If the request does not have a state property, or the state
  is not recognized, an unknown message will be returned.
  """
  @spec display_state(Request.t()) :: binary()
  @spec display_state(binary()) :: binary()
  def display_state(%Request{state: state}) do
    display_state(state)
  end

  def display_state(state) when is_binary(state) do
    case state do
      @pending_state -> pending_message()
      @accepted_state -> accepted_message()
      @enroute_state -> enroute_message()
      @arrived_state -> arrived_message()
      @completed_state -> completed_message()
      @canceled_state -> canceled_message()
      @offmission_state -> offmission_message()
      _ -> unknown_message()
    end
  end

  def display_state(_), do: unknown_message()

  def cancellable_state(%Request{state: state}) do
    case state do
      @pending_state -> true
      @accepted_state -> true
      @enroute_state -> false
      @arrived_state -> false
      @completed_state -> false
      @canceled_state -> false
      @offmission_state -> false
      _ -> true
    end
  end

  def pending_message, do: "Received"
  def accepted_message, do: "Booked"
  def enroute_message, do: "On the way"
  def arrived_message, do: "Arrived"
  def completed_message, do: "Completed"
  def canceled_message, do: "Canceled"
  def offmission_message, do: "Off-mission"
  def unknown_message, do: "Unknown"

  def progress do
    [
      pending_message(),
      accepted_message(),
      enroute_message(),
      arrived_message(),
      completed_message()
    ]
  end

  def request_cards(conn, requests) when is_list(requests) do
    ~E"""
    <%= for request <- requests do %>
      <%= request_card(conn, request) %>
    <% end %>
    """
  end

  def request_card(conn, request) do
    ~E"""
    <%= render "request_card.html", request: request, conn: conn %>
    """
  end

  def requester_tracker_link(%Request{id: request_id}) do
    path =
      Routes.request_path(
        CurbsideConcertsWeb.Endpoint,
        :tracker,
        TrackerCypher.encode(request_id)
      )

    link("Requester Tracker", to: path)
  end

  def truck_pickup_zip, do: "43235"

  # For safety the truck pickup/dropoff address has changed temporarily
  # original_location = "491 W Broad St., Columbus, OH 43215"
  def truck_pickup_dropoff_address, do: "7250 Sawmill Rd, Columbus OH 43235"

  def map_route_link(requests) do
    truck_location = truck_pickup_dropoff_address()

    addresses =
      requests
      |> Enum.map(&RequestAddress.full_address/1)
      |> Enum.join("/")

    link("Map this #{length(requests)} concert route",
      to: "https://www.google.com/maps/dir/#{truck_location}/#{addresses}/#{truck_location}",
      target: "_blank"
    )
  end

  def songs(playlist) when is_list(playlist) do
    [{"Please choose a song option", ""} | playlist]
  end

  def request_input(form, field, type: :phone) do
    class = class(form, field)

    ~E"""
    <%= telephone_input(form, field, data: [{:mask, nil}], class: class, placeholder: "Your answer") %>
    <%= error_tag form, field %>
    """
  end

  def request_input(form, field, type: :email) do
    class = class(form, field)

    ~E"""
    <%= email_input(form, field, class: class, placeholder: "Your answer") %>
    <%= error_tag form, field %>
    """
  end

  def request_input(form, field)
      when field in ~w|special_message nominee_address_notes request_reason nominee_description nominee_favorite_music_notes request_occasion special_instructions|a do
    class = class(form, field)

    ~E"""
    <%= textarea(form, field, class: class, placeholder: "Your answer") %>
    <%= error_tag form, field %>
    """
  end

  def request_input(form, field) do
    class = class(form, field)

    ~E"""
    <%= text_input(form, field, class: class, placeholder: "Your answer") %>
    <%= error_tag form, field %>
    """
  end

  def request_zip(form, field) do
    class = class(form, field)

    ~E"""
    <%= text_input(form, field, class: class, placeholder: "5-digit Zip") %>
    <%= error_tag form, field %>
    """
  end

  def request_select(form, field, options) do
    class = class(form, field)

    ~E"""
    <%= select(form, field, options, class: class) %>
    <%= error_tag form, field %>
    """
  end

  @months Enum.zip(
            1..12,
            ~w[January February March April May June July August September October November December]
          )
          |> Map.new()
  @weekdays Enum.zip(1..7, ~w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday])
            |> Map.new()
  @spec request_date(atom | Phoenix.HTML.Form.t(), atom) :: {:safe, [...]}
  def request_date(form, field, prompt \\ "Select a day") do
    today = Date.utc_today()

    options =
      1..30
      |> Enum.map(fn n ->
        date = Date.add(today, n)
        weekday = Date.day_of_week(date)
        display = "#{@weekdays[weekday]}, #{@months[date.month]} #{date.day}"
        {display, "#{date}"}
      end)
      |> Enum.filter(fn {display, _date} -> String.match?(display, ~r(Friday|Saturday|Sunday)) end)
      |> Enum.filter(fn {display, _date} -> String.match?(display, ~r(October)) end)

    actual = "#{Phoenix.HTML.Form.input_value(form, field)}"

    prompt =
      if actual == "" or Enum.any?(options, fn {_, date} -> date == actual end) do
        {prompt, ""}
      else
        {actual, actual}
      end

    ~E"""
    <%= select(form, field, [prompt | options]) %>
    <%= error_tag form, field %>
    """
  end

  def request_checkbox(form, field) do
    ~E"""
    <%= checkbox(form, field)%>
    <%= error_tag form, field %>
    """
  end

  def contact_preference_radio(form) do
    class = class(form, :contact_preference)

    ~E"""
      <label class="radio-button">
        <%= radio_button form, :contact_preference, :call_nominee, class: class %> <span>Call the nominee.</span>
      </label>
      <label class="radio-button">
        <%= radio_button form, :contact_preference, :call_requester, class: class %> <span>Call me and I'll contact the nominee.</span>
      </label>
      <label class="radio-button">
        <%= radio_button form, :contact_preference, :text_requester, class: class %> <span>Text me and I'll contact the nominee.</span>
      </label>
    """
  end

  def contact_preference(%Request{
        contact_preference: "call_nominee",
        nominee_name: name,
        nominee_phone: phone
      }),
      do: ~E"Call Nominee (<%= name %>) @ <%= phone_link(phone) %>"

  def contact_preference(%Request{
        contact_preference: "call_requester",
        requester_name: name,
        requester_phone: phone
      }),
      do: ~E"Call Requester (<%= name %>) @ <%= phone_link(phone) %>"

  def contact_preference(%Request{
        contact_preference: "text_requester",
        requester_name: requester_name,
        requester_phone: phone,
        nominee_name: nominee_name,
        song: song,
        session: %Session{
          musician: %Musician{
            name: name
          }
        }
      }) do
    message =
      "Hi there, #{requester_name}! This text is to let you know #{name} is coming soon to play #{
        song
      } for #{nominee_name}."
      |> URI.encode()
      |> String.replace("&", "%26")

    ~E"Text Requester (<%= requester_name %>) @ <%= text_link(phone, message) %>"
  end

  def contact_preference(%Request{
        contact_preference: "text_requester",
        requester_name: name,
        requester_phone: phone
      }),
      do: ~E"Text Requester (<%= name %>) @ <%= text_link(phone) %>"

  def contact_preference(%Request{contact_preference: preference}), do: preference

  def text_link(raw_number, message \\ "") do
    case simple_number(raw_number) do
      nil ->
        raw_number

      number ->
        if message == "" do
          ~E|<a href="sms:<%= number %>">Text <%= raw_number %></a>|
        else
          ~E|<a href="sms:<%= number %>&body=<%= message %>">Text <%= raw_number %></a>|
        end
    end
  end

  def phone_link(raw_number) do
    case simple_number(raw_number) do
      nil ->
        raw_number

      number ->
        ~E|<a href="tel:<%= number %>">Phone <%= raw_number %></a>|
    end
  end

  defp simple_number(number) when is_binary(number) do
    number = String.replace(number, ~r/\D/, "")
    if String.length(number) >= 10, do: number, else: nil
  end

  defp simple_number(_), do: nil

  defp class(form, field) do
    if form.errors[field], do: "not-valid", else: ""
  end

  def request_list_links() do
    endpoint = CurbsideConcertsWeb.Endpoint

    ~E"""
    <%= link "All", to: Routes.request_path(endpoint, :index) %>
    | <%= link "Unbooked", to: Routes.request_path(endpoint, :last_minute_gigs) %>
    | <%= link "Off-Mission", to: Routes.request_path(endpoint, :index, %{"state" => "offmission"})%>
    | <%= link "Canceled", to: Routes.request_path(endpoint, :index, %{"state" => "canceled"}) %>
    | <%= link "Archived", to: Routes.request_path(endpoint, :archived) %>
    """
  end

  def days_ago_message(%Request{} = request) do
    days_ago = TimeUtil.days_ago(request)

    case(days_ago) do
      0 -> gettext("Today")
      1 -> gettext("<b>1 day</b>")
      n -> gettext("<b>%{count} days</b>", count: n)
    end
    |> raw()
  end

  def days_ago_number(%Request{} = request) do
    TimeUtil.days_ago(request)
  end

  def days_ago_badge(%Request{} = request) do
    ~E"""
    <div class="days-ago-badge">
      <div class="days-text">
        <%= TimeUtil.days_ago(request) %>
      </div>
    </div>
    """
  end

  def request_action_links(%Request{state: state, archived: archived} = request, redirect_route) do
    ~E"""
    <%= if archived do %>
      <%= link "Unarchive this Request", to: Routes.request_path(CurbsideConcertsWeb.Endpoint, :unarchive, request, %{redirect: redirect_route}), method: :put, data: [confirm: "Are you sure?"] %>
    <% else %>
      <%= link "Edit", to: Routes.request_path(CurbsideConcertsWeb.Endpoint, :edit, request) %>
      <%= if state !== Requests.offmission_state() do %>
        | <%= link "Mark as Off-Mission", to: Routes.request_path(CurbsideConcertsWeb.Endpoint, :state, request, "offmission", %{redirect: redirect_route}), method: :put, data: [confirm: "Are you sure?"] %>
      <% else %>
        | <%= link "Mark as Received", to: Routes.request_path(CurbsideConcertsWeb.Endpoint, :state, request, "pending", %{redirect: redirect_route}), method: :put, data: [confirm: "Are you sure?"] %>
      <% end %>
      | <%= link "Archive this Request", to: Routes.request_path(CurbsideConcertsWeb.Endpoint, :archive, request, %{redirect: redirect_route}), method: :put, data: [confirm: "Are you sure?"] %>
    <% end %>
    """
  end

  def requester_can_see_session?(%Request{state: state, session: session}) do
    hidden_states = [Requests.canceled_state(), Requests.pending_state()]
    hidden? = session == nil or state in hidden_states
    !hidden?
  end
end
