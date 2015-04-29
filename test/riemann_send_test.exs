defmodule RiemannSendTest do
  use ExUnit.Case, async: false
  alias Riemann.Proto.Msg
  alias Riemann.Proto.Event

  setup do
    {:ok, server} = TestServer.start(Riemann.Worker.ok_msg, self)
    Application.start(:riemann)

    on_exit fn ->
      Application.stop(:riemann)
      TestServer.stop(server)
    end

    {:ok, server: server}
  end

  test "send/1 and send_async/1 send a single event" do
    event = [
      service: "riemann-elixir",
      metric: 1,
      attributes: [a: 1],
      description: "hurr durr"
    ]

    Riemann.send(event)
    assert_events_received(event)

    Riemann.send_async(event)
    assert_events_received(event)
  end

  test "send/1 and send_async/1 send many events" do
    events = [
      [
        service: "riemann-elixir",
        metric: 1,
        attributes: [a: 1],
        description: "hurr durr"
      ],
      [
        service: "riemann-elixir-2",
        metric: 1.123,
        attributes: [a: 1, "b": 2],
        description: "hurr durr dee durr"
      ],
      [
        service: "riemann-elixir-3",
        metric: 5.123,
        description: "hurr durr dee durr derp"
      ]
    ]

    Riemann.send(events)
    assert_events_received(events)

    Riemann.send_async(events)
    assert_events_received(events)
  end

  test "send/1 and send_async/1 raise if metric is missing" do
    events = [
      [
        service: "riemann-elixir",
        attributes: [a: 1],
        description: "hurr durr"
      ]
    ]

    assert_raise ArgumentError, fn ->
      Riemann.send(events)
    end

    assert_raise ArgumentError, fn ->
      Riemann.send_async(events)
    end
  end

  defp assert_events_received(events) do
    # TestServer sends us a message with what Riemann.send/1 sent it
    receive do
      msg -> assert Event.list_to_events(events) == Msg.decode(msg).events
    after 100 -> flunk
    end
  end
end