# Peering and options with safe ordering and short waits so everything works in one apply.

# Account ID lookup
data "aws_caller_identity" "a" { provider = aws.a }
data "aws_caller_identity" "b" { provider = aws.b }
data "aws_caller_identity" "c" { provider = aws.c }

# ---------------------------------------------------------------------------
# A <-> B
# ---------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "a_b" {
  provider      = aws.a
  vpc_id        = aws_vpc.a_vpc.id
  peer_vpc_id   = aws_vpc.b_vpc.id
  peer_owner_id = data.aws_caller_identity.b.account_id
  auto_accept   = false
  tags = { Name = "a-b-peering" }
}

resource "aws_vpc_peering_connection_accepter" "b_accept_a_b" {
  provider                  = aws.b
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b.id
  auto_accept               = true
  tags = { Name = "b-accept-a-b" }
}

resource "time_sleep" "a_b_wait" {
  depends_on      = [aws_vpc_peering_connection_accepter.b_accept_a_b]
  create_duration = "10s"
}

resource "aws_vpc_peering_connection_options" "a_b_requester_opts" {
  provider = aws.a
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [time_sleep.a_b_wait]
}

resource "aws_vpc_peering_connection_options" "a_b_accepter_opts" {
  provider = aws.b
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [time_sleep.a_b_wait]
}

# ---------------------------------------------------------------------------
# B <-> C
# ---------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "b_c" {
  provider      = aws.b
  vpc_id        = aws_vpc.b_vpc.id
  peer_vpc_id   = aws_vpc.c_vpc.id
  peer_owner_id = data.aws_caller_identity.c.account_id
  auto_accept   = false
  tags = { Name = "b-c-peering" }
}

resource "aws_vpc_peering_connection_accepter" "c_accept_b_c" {
  provider                  = aws.c
  vpc_peering_connection_id = aws_vpc_peering_connection.b_c.id
  auto_accept               = true
  tags = { Name = "c-accept-b-c" }
}

resource "time_sleep" "b_c_wait" {
  depends_on      = [aws_vpc_peering_connection_accepter.c_accept_b_c]
  create_duration = "10s"
}

resource "aws_vpc_peering_connection_options" "b_c_requester_opts" {
  provider = aws.b
  vpc_peering_connection_id = aws_vpc_peering_connection.b_c.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [time_sleep.b_c_wait]
}

resource "aws_vpc_peering_connection_options" "b_c_accepter_opts" {
  provider = aws.c
  vpc_peering_connection_id = aws_vpc_peering_connection.b_c.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [time_sleep.b_c_wait]
}

# ---------------------------------------------------------------------------
# A <-> C
# ---------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "a_c" {
  provider      = aws.a
  vpc_id        = aws_vpc.a_vpc.id
  peer_vpc_id   = aws_vpc.c_vpc.id
  peer_owner_id = data.aws_caller_identity.c.account_id
  auto_accept   = false
  tags = { Name = "a-c-peering" }
}

resource "aws_vpc_peering_connection_accepter" "c_accept_a_c" {
  provider                  = aws.c
  vpc_peering_connection_id = aws_vpc_peering_connection.a_c.id
  auto_accept               = true
  tags = { Name = "c-accept-a-c" }
}

resource "time_sleep" "a_c_wait" {
  depends_on      = [aws_vpc_peering_connection_accepter.c_accept_a_c]
  create_duration = "10s"
}

resource "aws_vpc_peering_connection_options" "a_c_requester_opts" {
  provider = aws.a
  vpc_peering_connection_id = aws_vpc_peering_connection.a_c.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [time_sleep.a_c_wait]
}

resource "aws_vpc_peering_connection_options" "a_c_accepter_opts" {
  provider = aws.c
  vpc_peering_connection_id = aws_vpc_peering_connection.a_c.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [time_sleep.a_c_wait]
}
