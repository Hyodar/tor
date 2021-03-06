/* Copyright (c) 2001 Matej Pfajfar.
 * Copyright (c) 2001-2004, Roger Dingledine.
 * Copyright (c) 2004-2006, Roger Dingledine, Nick Mathewson.
 * Copyright (c) 2007-2019, The Tor Project, Inc. */
/* See LICENSE for licensing information */

/**
 * @file cell_st.h
 * @brief Fixed-size cell structure.
 **/

#ifndef CELL_ST_H
#define CELL_ST_H

/** Parsed onion routing cell.  All communication between nodes
 * is via cells. */
struct cell_t {
  circid_t circ_id; /**< Circuit which received the cell. */
  uint8_t command; /**< Type of the cell: one of CELL_PADDING, CELL_CREATE,
                    * CELL_DESTROY, etc */
  uint8_t payload[CELL_PAYLOAD_SIZE]; /**< Cell body. */
};

// Franco
/** Struct to hold a cell and its sequence number. Used to queue
 * packets that arrive earlier than expected. */
struct early_cell_t {
  struct cell_t* cell;
  uint32_t sequence_num;
};

#endif /* !defined(CELL_ST_H) */
