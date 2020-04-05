defmodule HelloWeb.RequestView do
  use HelloWeb, :view

  alias Hello.Requests.Request
  alias Hello.Musicians.Musician
  alias Hello.Musicians.Session

  def required_star do
    ~E|<span class="required">*</span>|
  end

  def first_name(%Session{musician: %Musician{name: name}}) do
    name
    |> String.split()
    |> List.first()
  end

  def songs(playlist) when is_list(playlist) do
    [{"Please choose a song option", ""} | playlist]
  end

  def request_input(form, field) when field in ~w|special_message|a do
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

  def request_select(form, field, options) do
    class = class(form, field)

    ~E"""
    <%= select(form, field, options, class: class) %>
    <%= error_tag form, field %>
    """
  end

  def contact_preference_radio(form) do
    class = class(form, :contact_preference)

    ~E"""
    <div>We'll call ahead when we're on our way (about 15 to 30 minutes before we arrive). Given that some older folks can be skeptical of calls... you have the option for us to call you, or the nominee - please choose an option below. <%= required_star() %></div>
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

  def hero_image() do
    alt_text =
      "A man sitting in the bed of a pickup truck plays guitar for an elderly woman standing in her driveway. A speech bubble over the man says \"That song was for you. People care about you. This is from your daughter: 'Mom, we know it's hard to be alone but we want you to be safe. We hope this song brightens your day. We love you.'\""

    ~E"""
    <img src="/images/for_you.png" alt="<%= alt_text %>" />
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
        requester_name: name,
        requester_phone: phone
      }),
      do: ~E"Text Requester (<%= name %>) @ <%= text_link(phone) %>"

  def contact_preference(_), do: "unknown"

  def text_link(raw_number) do
    case simple_number(raw_number) do
      nil ->
        raw_number

      number ->
        ~E|<a href="sms:<%= number %>">Text <%= raw_number %></a>|
    end
  end

  def phone_link(raw_number) do
    case simple_number(raw_number) do
      nil ->
        raw_number

      number ->
        ~E|<a href="sms:<%= number %>">Text <%= raw_number %></a>|
    end
  end

  defp simple_number(number) do
    number = String.replace(number, ~r/\D/, "")
    if String.length(number) >= 10, do: number, else: nil
  end

  defp class(form, field) do
    if form.errors[field], do: "not-valid", else: ""
  end
end
