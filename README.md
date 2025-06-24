# 🚀 Gigdao - Freelancer DAO Platform

A decentralized freelancing platform built on Stacks blockchain that combines reputation tracking with secure payment escrow functionality.

## 🌟 Features

- **💼 Gig Management**: Create, apply to, and manage freelance gigs
- **🔒 Payment Escrow**: Secure payment holding until work completion
- **⭐ Reputation System**: Track ratings and build professional reputation
- **👥 Dual Profiles**: Separate profiles for freelancers and clients
- **🛡️ Dispute Protection**: Built-in dispute period for payment releases
- **💰 Platform Fees**: Automated fee collection (2.5% default)

## 📋 Contract Functions

### Public Functions

#### For Clients
- `create-gig(title, description, payment)` - Create a new gig with escrowed payment
- `assign-freelancer(gig-id, freelancer)` - Assign a freelancer to your gig
- `release-payment(gig-id)` - Release payment after dispute period
- `rate-user(gig-id, rating, review)` - Rate the freelancer (1-5 stars)

#### For Freelancers
- `apply-to-gig(gig-id, proposal)` - Apply to an open gig
- `complete-gig(gig-id)` - Mark gig as completed
- `rate-user(gig-id, rating, review)` - Rate the client (1-5 stars)
