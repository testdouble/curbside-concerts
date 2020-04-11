defmodule CurbsideConcertsWeb.SessionBookerLive do
  @moduledoc """
  Live view for the Session Booking; adding requests to sessions.
  """
  use CurbsideConcertsWeb, :live_view

  alias CurbsideConcerts.LexoRanker
  alias CurbsideConcerts.Musicians
  alias CurbsideConcerts.Musicians.Session
  alias CurbsideConcerts.Requests
  alias CurbsideConcerts.Requests.Request
  alias CurbsideConcertsWeb.RequestView

  def mount(%{"session_id" => session_id} = _params, _session, socket) do
    unbooked_requests = Requests.all_unbooked_requests()
    session = Musicians.find_session(session_id)

    # PubSub turned off for now
    # CurbsideConcertsWeb.Endpoint.subscribe("session:#{session_id}")
    # CurbsideConcertsWeb.Endpoint.subscribe("unbooked")

    socket =
      socket
      |> assign(:unbooked_requests, unbooked_requests)
      |> assign(:session_requests, session.requests)
      |> assign(:session, session)
      |> assign(:saved, false)

    {:ok, socket}
  end

  def handle_event(
        "session_booked_up",
        _params,
        %{
          assigns: %{
            session: %Session{id: session_id},
            unbooked_requests: unbooked_requests,
            session_requests: session_requests
          }
        } = socket
      ) do
    Enum.reduce(unbooked_requests, nil, fn request, last_rank ->
      last_rank = LexoRanker.calculate(last_rank, nil)
      Requests.update_request(request, %{rank: last_rank, session_id: nil, session: nil})
      last_rank
    end)

    Enum.reduce(session_requests, nil, fn request, last_rank ->
      last_rank = LexoRanker.calculate(last_rank, nil)
      Requests.update_request(request, %{rank: last_rank, session_id: session_id})
      last_rank
    end)

    # TODO change status of the session_requests

    unbooked_requests = Requests.all_unbooked_requests()
    session = Musicians.find_session(session_id)

    {:noreply,
     assign(socket,
       saved: true,
       unbooked_requests: unbooked_requests,
       session_requests: session.requests,
       session: session
     )}
  end

  def handle_event(
        "move_request",
        %{
          "request_id" => request_id,
          "over_request_id" => over_request_id,
          "from_session_id" => from_session_id,
          "to_session_id" => to_session_id
        },
        %{assigns: %{unbooked_requests: unbooked_requests, session_requests: session_requests}} =
          socket
      ) do
    booked? = !is_nil(to_session_id)
    internal_move? = from_session_id == to_session_id

    {unbooked_requests, session_requests} =
      if booked? do
        if internal_move? do
          session_requests = internal_move_request(request_id, over_request_id, session_requests)
          {unbooked_requests, session_requests}
        else
          move_request(request_id, over_request_id, unbooked_requests, session_requests)
        end
      else
        if internal_move? do
          unbooked_requests =
            internal_move_request(request_id, over_request_id, unbooked_requests)

          {unbooked_requests, session_requests}
        else
          {session_requests, unbooked_requests} =
            move_request(request_id, over_request_id, session_requests, unbooked_requests)

          {unbooked_requests, session_requests}
        end
      end

    # Turned of PubSub for now
    # CurbsideConcertsWeb.Endpoint.broadcast_from(
    #   self(),
    #   "request_booking:#{session_id}",
    #   "message",
    #   %{
    #     session: session_id
    #   }
    # )

    {:noreply,
     assign(socket,
       unbooked_requests: unbooked_requests,
       session_requests: session_requests,
       saved: false
     )}
  end

  defp internal_move_request(request_id, over_request_id, list) do
    request =
      Enum.find(list, fn %Request{id: id} ->
        "#{request_id}" == "#{id}"
      end)

    over_request =
      Enum.find(list, fn %Request{id: id} ->
        "#{over_request_id}" == "#{id}"
      end)

    list = List.delete(list, request)

    if over_request do
      over_request_index =
        Enum.find_index(list, fn %Request{id: id} ->
          "#{over_request_id}" == "#{id}"
        end)

      List.insert_at(list, over_request_index, request)
    else
      list ++ [request]
    end
  end

  defp move_request(request_id, over_request_id, from_list, to_list) do
    IO.inspect(from_list, label: "from_list")

    request =
      Enum.find(from_list, fn %Request{id: id} ->
        IO.inspect({id, request_id}, label: "{id, request_id}")
        "#{request_id}" == "#{id}"
      end)

    over_request =
      Enum.find(to_list, fn %Request{id: id} ->
        "#{over_request_id}" == "#{id}"
      end)

    IO.inspect({request, over_request}, label: "{request, over_request}")

    from_list = List.delete(from_list, request)
    to_list = List.delete(to_list, request)

    to_list =
      if over_request do
        over_request_index =
          Enum.find_index(to_list, fn %Request{id: id} ->
            "#{over_request_id}" == "#{id}"
          end)

        List.insert_at(to_list, over_request_index, request)
      else
        to_list ++ [request]
      end

    {from_list, to_list}
  end

  # def handle_info(
  #       %{event: "message", payload: %{session: session_id}},
  #       %{assigns: %{logs: logs}} = socket
  #     ) do
  #   {:noreply,
  #    assign(socket,
  #      #  unbooked_requests: unbooked_requests,
  #      logs: ["Them: Booking #{session_id}" | logs]
  #    )}
  # end

  def render(assigns) do
    ~L"""
    <div class="booker">
      <div class="card">
        Drag and drop requests. <button phx-click="session_booked_up">Click here</button> when you are done.
        <%= if @saved do %>
          <br><br>SAVED!
        <% end %>
      </div>
      <div class="columns">
        <div class="column">
          <h2>Unbooked Requests</h2>

          <%= for request <- @unbooked_requests do %>
            <%= render_request_card(assigns, request) %>
          <% end %>
          <%= if @unbooked_requests == [] do %>
            <div class="card">
              There are no unbooked requests.
            </div>
          <% end %>
        </div>

        <div class="column" phx-value-session-id="<%= @session.id %>">
          <h2>Requests in Session: <%= @session.name %></h2>

          <%= unless @session_requests == [] do %>
            <%= RequestView.map_route_link(@session_requests) %>
          <% end %>
          <%= for request <- @session_requests do %>
            <%= render_request_card(assigns, request) %>
          <% end %>
          <%= if @session_requests == [] do %>
            <div class="card">
              There are no requests in this session yet.
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp render_request_card(
         assigns,
         %Request{
           id: request_id,
           nominee_address: nominee_address,
           special_message: special_message
         } = request
       ) do
    ~L"""
    <div phx-hook="RequestBookerCard"
         phx-value-request-id="<%= request_id %>"
         class="draggable-card"
         draggable="true">
      <div class="card">
        <b>email:</b> <%= request.requester_email %><br>
        <b>genres:</b> <%= Enum.map(request.genres, fn g -> g.name end) |> Enum.join(", ") %><br>
        <b>Address:</b> <%= nominee_address %><br>
        <b>Special Message:</b> <%= special_message %><br>
        <b>state:</b> <%= request.state %><br>
        <b>contact_preference:</b> <%= request.contact_preference %><br>
        <b>nominee_name:</b> <%= request.nominee_name %><br>
        <b>nominee_phone:</b> <%= request.nominee_phone %><br>
        <b>requester_name:</b> <%= request.requester_name %><br>
        <b>requester_phone:</b> <%= request.requester_phone %><br>
      </div>
    </div>
    """
  end
end