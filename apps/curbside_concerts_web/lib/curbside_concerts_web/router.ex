defmodule CurbsideConcertsWeb.Router do
  use CurbsideConcertsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug(CurbsideConcertsWeb.Plugs.SetCurrentUser)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :requires_auth do
    plug CurbsideConcertsWeb.Plugs.AuthenticateUser
  end

  scope "/", CurbsideConcertsWeb do
    pipe_through :browser

    get "/", LandingController, :index
    get "/request/:session_id", RequestController, :new
    post "/request", RequestController, :create

    get "/admin", AdminController, :index

    get("/sign-in", AccountSessionController, :new)
    post("/sign-in", AccountSessionController, :create)
  end

  scope "/", CurbsideConcertsWeb do
    pipe_through [:browser, :requires_auth]

    get "/musician_builder/new", MusicianController, :new
    post "/musician_builder/new", MusicianController, :create
    get "/musician_builder", MusicianController, :index

    resources "/session_builder", SessionController

    # get "/session_builder/new", SessionController, :new
    # post "/session_builder/new", SessionController, :create
    # get "/session_builder/:session_id", SessionController, :update
    # post "/session_builder/:session_id", SessionController, :save
    # get "/session_builder", SessionController, :index

    get "/gigs", RequestController, :index
    get "/gigs/:musician", RequestController, :index

    delete("/sign-out", AccountSessionController, :delete)
  end

  # Other scopes may use custom stacks.
  # scope "/api", CurbsideConcertsWeb do
  #   pipe_through :api
  # end
end